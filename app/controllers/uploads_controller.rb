# frozen_string_literal: true

class UploadsController < ApplicationController
  rescue_from ActionController::MissingFile, with: :raise_not_found_exception
  rescue_from SecurityError, with: :log_and_raise_not_found_exception
  rescue_from CanCan::AccessDenied, with: :log_and_raise_not_found_exception

  MODELS_OVERRIDES = {
    "operator_document_file" => "document_file",
    "documents" => "uploaded_document"
  }.freeze

  def download
    sanitize_filepath
    parse_upload_path
    ensure_valid_db_record
    track_download if trackable_request?
    check_authorization! if needs_authorization?
    send_file @sanitized_filepath, disposition: :inline
  end

  private

  def sanitize_filepath
    filepath = "#{params[:rest]}.#{params[:format]}"
    allowed_path = File.realpath(allowed_directory)
    full_path = File.realpath(File.join(allowed_path, filepath))

    raise_not_found_exception unless full_path.start_with?(allowed_path + File::SEPARATOR)

    @sanitized_filepath = full_path
    @relative_filepath = full_path.gsub(allowed_path + File::SEPARATOR, "")
  rescue Errno::ENOENT
    raise_not_found_exception
  end

  def parse_upload_path
    path_parts = @relative_filepath.split("/")

    raise_not_found_exception if path_parts.length < 4

    model_key = path_parts[0].downcase
    @model_name = (MODELS_OVERRIDES[model_key] || model_key).downcase
    @uploader_name = path_parts[1].downcase
    @record_id = path_parts[2].to_i
    @filename = path_parts[3..].join("/")
  end

  # extra security step, do not let download antything for removed records or not saved in DB
  # we already have sanitized file path that should be enough, but this also will ensure no protected file is downloaded
  def ensure_valid_db_record
    raise_not_found_exception unless allowed_models.include?(@model_name)

    @model_class = @model_name.classify.constantize
    raise_not_found_exception unless @model_class.uploaders.keys.map(&:to_s).include?(@uploader_name) # ensure valid uploader

    find_record
    ensure_valid_filename
  end

  def find_record
    @record = if current_user.present? && current_user.admin? && @model_class.respond_to?(:with_deleted)
      @model_class.with_deleted.find(@record_id)
    else
      @model_class.find(@record_id)
    end
    @uploader = @record.public_send(@uploader_name)
  rescue ActiveRecord::RecordNotFound, NameError
    raise_not_found_exception
  end

  def ensure_valid_filename
    # do not check for admins, could download other files like from papertrail history
    return if current_user.present? && current_user.admin?

    db_filenames = [@uploader.file.file, *@uploader.versions.values.map { |v| v.file.file }].map { |f| File.basename(f) }

    unless db_filenames.include?(File.basename(@sanitized_filepath))
      raise_not_found_exception
    end
  end

  def cookie_download_users
    cookies
      .select { |name, _v| name.ends_with?("download_user") }
      .map do |name, download_token|
        payload = Rails.application.message_verifier("download_token").verify(download_token)
        User.find_by(id: payload["user_id"])
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end.compact
  end

  def check_authorization!
    raise SecurityError unless download_users.any? { it.can?(:download_protected, @record) }
  end

  def download_users
    [current_user, *cookie_download_users].compact
  end

  def needs_authorization?
    @uploader.protected?
  end

  def allowed_models
    uploads_root = ApplicationUploader.new.root.join("uploads")
    Dir.entries(uploads_root)
      .select { |entry| File.directory?(uploads_root.join(entry)) }
      .reject { |entry| entry.start_with?(".") || entry == "tmp" }
      .map { |entry| MODELS_OVERRIDES[entry.downcase] || entry }
  end

  def track_download
    TrackFileDownloadJob.perform_later(
      client_id,
      request.remote_ip,
      request.referer,
      request_source,
      request_source_info,
      request.url,
      @filename,
      @model_name
    )
  end

  def client_id
    session.id&.to_s || SecureRandom.uuid
  end

  def trackable_request?
    @uploader.respond_to?(:track_downloads?) && @uploader.track_downloads? &&
      !bot_request? &&
      !admin_panel_request?
  end

  def bot_request?
    detector = DeviceDetector.new(request.user_agent)
    detector.bot? || (detector.device_type.nil? && detector.os_name.nil?)
  end

  def request_source
    return "direct" if request.referer.blank?
    return "internal" if request.referer.start_with?(root_url)
    return "search_engine" if search_engine_referer.present?

    "external_site"
  end

  def request_source_info
    return search_engine_referer if search_engine_referer.present?

    nil
  end

  def search_engine_referer
    return nil unless request.referer.present?

    %w[google bing yahoo duckduckgo baidu].each do |engine|
      return engine if request.referer.include?(engine)
    end

    nil
  end

  def admin_panel_request?
    referer = request.referer.to_s
    return false if referer.blank?

    admin_paths = ["/admin", "/observations-tool"]
    admin_paths.any? { |path| referer.include?(path) }
  end

  def allowed_directory
    Rails.env.test? ? File.join(Rails.root, "tmp", "uploads") : File.join(Rails.root, "uploads")
  end

  def log_and_raise_not_found_exception
    msg_info = {
      user_id: current_user&.id,
      source: request_source,
      source_info: request_source_info,
      bot_request: bot_request?,
      path: @sanitized_filepath
    }
    msg = "Unauthorized file download attempt: #{msg_info}"
    Rails.logger.warn(msg)
    Sentry.capture_message(msg) if ENV["SENTRY_LOG_UNAUTHORIZED_DOWNLOADS"] == "true"
    raise_not_found_exception
  end

  def raise_not_found_exception
    raise ActionController::RoutingError, "Not found or your download session has expired (try clicking on the link again)"
  end
end

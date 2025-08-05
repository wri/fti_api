# frozen_string_literal: true

class UploadsController < ApplicationController
  rescue_from ActionController::MissingFile, with: :raise_not_found_exception

  MODELS_OVERRIDES = {
    "operator_document_file" => "document_file",
    "documents" => "uploaded_document"
  }.freeze

  TRACKABLE_MODELS = [
    "document_file",
    "documents",
    "gov_document",
    "gov_file",
    "newsletter",
    "observation_document",
    "observation_report"
  ].freeze

  def download
    sanitize_filepath
    parse_upload_path
    track_download if trackable_request?
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
    @model_name = MODELS_OVERRIDES[model_key] || model_key
    @filename = path_parts[3..].join("/")
  end

  def track_download
    TrackFileDownloadJob.perform_later(client_id, request.url, @filename, @model_name)
  end

  def client_id
    session.id&.to_s || SecureRandom.uuid
  end

  def trackable_request?
    TRACKABLE_MODELS.include?(@model_name) &&
      !bot_request? &&
      !admin_panel_request?
  end

  def bot_request?
    user_agent = request.user_agent.to_s.downcase
    bot_patterns = [
      /bot/, /spider/, /crawl/, /slurp/, /search/, /googlebot/,
      /bingbot/, /yandexbot/, /duckduckbot/, /facebookexternalhit/,
      /headlesschrome/, /phantomjs/, /selenium/, /curl/, /wget/, /python-requests/,
      /ruby/, /java/, /httpclient/, /scrapy/, /mechanize/, /go-http-client/
    ]

    bot_patterns.any? { |pattern| user_agent.match?(pattern) }
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

  def raise_not_found_exception
    raise ActionController::RoutingError, "Not Found"
  end
end

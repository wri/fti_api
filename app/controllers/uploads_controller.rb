# frozen_string_literal: true

class UploadsController < ApplicationController
  include SecureSendFile

  rescue_from ActionController::MissingFile, with: :raise_not_found_exception

  ALLOWED_MODELS_OVERRIDES = {
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
    parse_upload_path
    track_download if trackable_request?
    secure_send_file allowed_directory, @filepath, disposition: :inline
  end

  private

  def parse_upload_path
    path_parts = "#{params[:rest]}.#{params[:format]}".split("/")
    @filepath = "#{params[:rest]}.#{params[:format]}"

    raise_not_found_exception if path_parts.length < 4

    model_key = path_parts[0].downcase
    @model_name = ALLOWED_MODELS_OVERRIDES[model_key] || model_key
    @filename = path_parts[3..].join("/")

    raise_not_known_model unless allowed_models.include?(@model_name) # extra security check
  end

  def track_download
    TrackDownloadJob.perform_later(request.url, @filename, @model_name)
  end

  def trackable_request?
    TRACKABLE_MODELS.include?(@model_name) && !bot_request?
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

  def allowed_models
    Dir.entries(Rails.root.join("uploads"))
      .select { |entry| File.directory?(Rails.root.join("uploads", entry)) }
      .reject { |entry| entry.start_with?(".") || entry == "tmp" }
      .map { |entry| ALLOWED_MODELS_OVERRIDES[entry.downcase] || entry }
  end

  def allowed_directory
    Rails.env.test? ? File.join(Rails.root, "tmp", "uploads") : File.join(Rails.root, "uploads")
  end

  def raise_not_found_exception
    raise ActionController::RoutingError, "Not Found"
  end

  def raise_not_known_model
    raise ActionController::RoutingError, "Not Known Model"
  end
end

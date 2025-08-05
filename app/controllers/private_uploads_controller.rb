# frozen_string_literal: true

class PrivateUploadsController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActionController::MissingFile, with: :raise_not_found_exception

  def download
    sanitize_filepath
    send_file @sanitized_filepath, disposition: :inline
  end

  private

  def sanitize_filepath
    filepath = "#{params[:rest]}.#{params[:format]}"
    allowed_path = File.realpath(allowed_directory)
    full_path = File.realpath(File.join(allowed_path, filepath))

    raise_not_found_exception unless full_path.start_with?(allowed_path + File::SEPARATOR)

    @sanitized_filepath = full_path
  rescue Errno::ENOENT
    raise_not_found_exception
  end

  def authenticate_user!
    if current_user.present?
      super
    else
      raise_not_found_exception
    end
  end

  def allowed_filepath
    return File.join(Rails.root, "tmp", "private", "uploads") if Rails.env.test?

    File.join(Rails.root, "private", "uploads")
  end

  def raise_not_found_exception
    raise ActionController::RoutingError, "Not Found"
  end
end

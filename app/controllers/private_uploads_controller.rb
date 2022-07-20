# frozen_string_literal: true

class PrivateUploadsController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActionController::MissingFile, with: :raise_not_found_exception

  def download
    filepath = "#{params[:rest]}.#{params[:format]}"
    send_file_inside allowed_filepath, filepath, disposition: :inline
  end

  private

  def authenticate_user!
    if current_user.present?
      super
    else
      raise_not_found_exception
    end
  end

  def allowed_filepath
    return File.join(Rails.root, 'tmp', 'private', 'uploads') if Rails.env.test?

    File.join(Rails.root, 'private', 'uploads')
  end

  def send_file_inside(allowed_path, filename, options = {})
    path = File.expand_path(File.join(allowed_path, filename))
    if path.match Regexp.new('^' + Regexp.escape(allowed_path))
      send_file path, options
    else
      raise_not_found_exception
    end
  end

  def raise_not_found_exception
    raise ActionController::RoutingError, 'Not Found'
  end
end

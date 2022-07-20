# frozen_string_literal: true

class PrivateUploadsController < ApplicationController
  before_action :authenticate_user!

  def download
    filepath = "#{params[:rest]}.#{params[:format]}"
    send_file_inside File.join(Rails.root, 'private', 'uploads'), filepath, disposition: :inline
  end

  private

  def send_file_inside(allowed_path, filename, options = {})
    path = File.expand_path(File.join(allowed_path, filename))
    if path.match Regexp.new('^' + Regexp.escape(allowed_path))
      send_file path, options
    else
      raise 'Disallowed file requested'
    end
  end
end

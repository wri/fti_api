# frozen_string_literal: true

class PartnerLogoUploader < ApplicationUploader
  include CarrierWave::MiniMagick

  def extension_whitelist
    %w(jpg jpeg gif png svg tiff)
  end

  def default_url(*args)
    ActionController::Base.helpers.asset_path('' + [version_name, 'placeholder.png'].compact.join('_'))
  end

  version :unmodified

  # This is just for active admin
  version :original do
    process resize_to_fill: [80, 80]
  end
end

# frozen_string_literal: true

class NewsletterImageUploader < ApplicationUploader
  include CarrierWave::MiniMagick

  def extension_allowlist
    %w[jpg jpeg gif png svg tiff]
  end

  version :thumbnail do
    process resize_to_fit: [nil, 200]
  end
end

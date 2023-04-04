# frozen_string_literal: true

class LogoUploader < ApplicationUploader
  include CarrierWave::MiniMagick

  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  process resize_to_fit: [1200, 1200]

  version :thumbnail do
    process resize_to_fill: [120, 120, "Center"]
  end

  version :square do
    process resize_to_fill: [600, 600, "Center"]
  end

  version :medium do
    process resize_to_fill: [600, 600]
  end

  # This is just for active admin
  version :original do
    process resize_to_fill: [80, 80]
  end
end

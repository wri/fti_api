# frozen_string_literal: true

class DocumentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/documents/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def exists?
    file.present?
  end
end

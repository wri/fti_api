# frozen_string_literal: true

class DocumentUploader < ApplicationUploader
  def store_dir
    "uploads/documents/#{model.id}"
  end

  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end
end

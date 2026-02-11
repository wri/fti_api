# frozen_string_literal: true

class DocumentUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end

  def track_downloads?
    true
  end

  # to fix the issue with uploading file with the same name, we don't want to add suffixes
  # here is similar issue discussed: https://github.com/carrierwaveuploader/carrierwave/issues/2682
  def deduplicated_filename
    filename
  end
end

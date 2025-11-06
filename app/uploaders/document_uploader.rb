# frozen_string_literal: true

class DocumentUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end

  def track_downloads?
    true
  end
end

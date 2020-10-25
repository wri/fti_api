# frozen_string_literal: true

class DocumentFileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/operator_document_file/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def exists?
    file.present?
  end

  def filename
    filename = model.file_name
    extension = super&.split('.')&.last
    extension = extension.blank? ? '' : '.' + extension
    filename + extension
  end

  def original_filename
    if file.present?
      file.filename
    else
      super
    end
  end
end

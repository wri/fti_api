# frozen_string_literal: true

class OperatorDocumentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/operator_document/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def exists?
    file.present?
  end

  def filename
    return if super.blank?
    filename = '' + model.operator.name[0...30] + '-' + model.required_operator_document.name[0...100] + '-' + Date.today.to_s
    filename += '.' + super.split('.').last if super.split('.').any?
    filename
  end

  def original_filename
    if file.present?
      file.filename
    else
      super
    end
  end
end

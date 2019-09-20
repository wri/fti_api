# frozen_string_literal: true

class GovDocumentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/gov_document/#{model.gov_document.id}/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def exists?
    file.present?
  end

  def filename
    return if super.blank?
    filename = '' + model.gov_document.required_gov_document.name + '-' + Date.today.to_s
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

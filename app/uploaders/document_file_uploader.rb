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
    return super if model.operator_document.nil?

    filename = [
      model.operator_document.operator.name[0...30]&.parameterize,
      model.operator_document.required_operator_document.name[0...100]&.parameterize,
      Date.today.to_s
    ].compact.join('-')

    filename + File.extname(super)
  end

  def original_filename
    if file.present?
      file.filename
    else
      super
    end
  end
end

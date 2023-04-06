# frozen_string_literal: true

class DocumentFileUploader < ApplicationUploader
  def store_dir
    "uploads/operator_document_file/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end

  def filename
    return super if model.operator_document.nil?
    return if super.blank?

    filename = [
      model.operator_document.operator.name[0...30]&.parameterize,
      model.operator_document.required_operator_document.name[0...100]&.parameterize,
      Date.today.to_s
    ].compact.join("-")

    sanitize_filename(filename + File.extname(super))
  end
end

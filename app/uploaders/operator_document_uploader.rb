# frozen_string_literal: true

class OperatorDocumentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/operator_document/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc htm html docx txt csv xml)
  end

  def exists?
    !file.blank?
  end

  def original_filename
    file.filename
  end
end

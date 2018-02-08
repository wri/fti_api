# frozen_string_literal: true

class OperatorDocumentAnnexUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/operator_document_annex/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def exists?
    file.present?
  end

  def filename
    return if super.blank?
    annex_number = model.operator_document.operator_document_annexes.count + 1
    filename = "Annex_#{annex_number.to_s}_" + model.operator_document&.attachment&.file&.basename&.parameterize
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

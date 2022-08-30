# frozen_string_literal: true

class OperatorDocumentAnnexUploader < ApplicationUploader
  def store_dir
    "uploads/operator_document_annex/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def filename
    return if super.blank?

    suffix = model&.operator_document&.attachment&.file&.basename&.parameterize || 'no_document'
    filename = "Annex_#{Time.now.to_i}_" + suffix
    filename += '.' + super.split('.').last if super.split('.').any?
    filename
  end
end

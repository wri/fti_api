# frozen_string_literal: true

class ObservationDocumentUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end

  def filename
    return if super.blank?

    filename = if model.name.present?
      model.name[0...100]&.parameterize
    else
      [
        model.id,
        (model.document_type || "other").parameterize
      ].join("-")
    end

    sanitize_filename(filename + File.extname(super))
  end

  def private_upload?
    model.deleted?
  end
end

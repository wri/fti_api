# frozen_string_literal: true

class OperatorDocumentAnnexUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end

  def track_downloads?
    true
  end

  # def protected?
  #   model.needs_authorization_before_downloading?
  # end

  def filename
    return if super.blank?

    suffix = model.operator_document&.document_file&.attachment&.file&.basename&.parameterize&.first(200) || "no_document"
    filename = "Annex_#{creation_timestamp}_" + suffix
    filename += "." + super.split(".").last if super.split(".").any?
    sanitize_filename(filename)
  end

  private

  # as described in wiki https://github.com/carrierwaveuploader/carrierwave/wiki/How-to%3A-Create-random-and-unique-filenames-for-all-versioned-files
  # to prevent issues with file name different than saved in DB
  def creation_timestamp
    var = :"@#{mounted_as}_creation_timestamp"
    model.instance_variable_get(var) or model.instance_variable_set(var, Time.now.to_i)
  end
end

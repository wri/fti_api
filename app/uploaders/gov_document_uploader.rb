# frozen_string_literal: true

class GovDocumentUploader < ApplicationUploader
  configure do |config|
    config.remove_previously_stored_files_after_update = false
  end

  def extension_allowlist
    %w[pdf doc docx txt csv xml jpg jpeg png exif tiff bmp]
  end

  def track_downloads?
    true
  end

  def filename
    return if super.blank?

    filename = "" + model.required_gov_document.name.first(200) + "-" + random_token + "-" + Time.zone.today.to_s
    filename += "." + super.split(".").last if super.split(".").any?
    sanitize_filename(filename)
  end

  def private_upload?
    model.deleted? || !model.paper_trail.live?
  end

  protected

  def random_token
    var = :"@#{mounted_as}_random_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(2))
  end
end

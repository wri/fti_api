# frozen_string_literal: true

class ObservationReportUploader < ApplicationUploader
  def extension_allowlist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def filename
    return if super.blank?

    date = model.publication_date&.to_date&.to_s || model.created_at&.to_date&.to_s || Date.today.to_s
    filename = '' + model.title[0...50]&.parameterize + '-' + date
    filename += '.' + super.split('.').last if super.split('.').any?
    sanitize_filename(filename)
  end

  def private_upload?
    model.deleted?
  end
end

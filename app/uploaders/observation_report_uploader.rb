# frozen_string_literal: true

class ObservationReportUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf]
  end

  def track_downloads?
    true
  end

  def filename
    return if super.blank?

    date = model.publication_date&.to_date&.to_s || model.created_at&.to_date&.to_s || Time.zone.today.to_s
    filename = "" + model.title[0...50]&.parameterize + "-" + date
    filename += "." + super.split(".").last if super.split(".").any?
    sanitize_filename(filename)
  end
end

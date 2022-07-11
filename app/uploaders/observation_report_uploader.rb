# frozen_string_literal: true

class ObservationReportUploader < ApplicationUploader
  def store_dir
    directory = model.deleted? ? 'private_uploads' : 'uploads'
    "#{directory}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def root
    return Rails.root if model.deleted?

    Rails.root.join('public')
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def filename
    return if super.blank?

    date = model.publication_date&.to_date&.to_s || model.created_at&.to_date&.to_s || Date.today.to_s
    filename = '' + model.title[0...50]&.parameterize + '-' + date
    filename += '.' + super.split('.').last if super.split('.').any?
    filename
  end
end

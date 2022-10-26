# frozen_string_literal: true

class GovDocumentUploader < ApplicationUploader
  def extension_allowlist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def filename
    return if super.blank?

    filename = '' + model.gov_document.required_gov_document.name + '-' + Date.today.to_s
    filename += '.' + super.split('.').last if super.split('.').any?
    filename
  end
end

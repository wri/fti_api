# frozen_string_literal: true

class ObservationDocumentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(pdf doc docx txt csv xml jpg jpeg png exif tiff bmp)
  end

  def exists?
    file.present?
  end

  def filename
    return super if model.observation.nil?
    return if super.blank?

    filename = if model.name.present?
                 model.name[0...100]&.parameterize
               else
                 [
                   model.id,
                   (model.observation.evidence_type || 'other').parameterize
                 ].join('-')
               end

    filename + File.extname(super)
  end

  def original_filename
    if file.present?
      file.filename
    else
      super
    end
  end
end

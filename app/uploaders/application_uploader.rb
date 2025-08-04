# frozen_string_literal: true

class ApplicationUploader < CarrierWave::Uploader::Base
  storage :file

  def root
    result = Rails.root
    result = Rails.root.join("private") if private_upload?
    result = result.to_s.gsub(Rails.root.to_s, Rails.root.join("tmp").to_s) if Rails.env.test?
    result
  end

  def cache_dir
    return Rails.root.join("tmp", "uploads", "cache") if Rails.env.test?

    super
  end

  def url(*args)
    return super&.gsub("/uploads/", "/private/uploads/") if private_upload?

    super
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def exists?
    file.present?
  end

  def private_upload?
    false
  end

  def original_filename
    if file.present?
      file.filename
    else
      super
    end
  end

  def sanitize_filename(filename)
    filename.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�").strip.tr("\u{202E}%$|:;/\t\r\n\\", "-")
  end
end

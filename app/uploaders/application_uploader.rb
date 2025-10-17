# frozen_string_literal: true

class ApplicationUploader < CarrierWave::Uploader::Base
  storage :file

  def root
    return Rails.root.join("tmp") if Rails.env.test?

    Rails.root
  end

  def cache_dir
    return Rails.root.join("tmp", "uploads", "cache") if Rails.env.test?

    super
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def exists?
    file.present?
  end

  def track_downloads?
    false
  end

  def protected?
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

# frozen_string_literal: true

class ApplicationUploader < CarrierWave::Uploader::Base
  storage :file

  def root
    return private_root if private_upload?

    public_root
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

  def public_root
    return Rails.root.join("tmp") if Rails.env.test?

    Rails.root
  end

  def private_root
    return Rails.root.join("tmp", "private") if Rails.env.test?

    Rails.root.join("private")
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

# frozen_string_literal: true

class NewsletterUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf]
  end

  def filename
    return if super.blank?

    filename = [
      model.title[0...30]&.parameterize,
      model.date.to_s
    ].compact.join("-")

    sanitize_filename(filename + File.extname(super))
  end
end

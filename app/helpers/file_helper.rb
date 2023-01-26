module FileHelper
  def preview_file_tag(file, options = {})
    return if file.blank?
    return unless file.exists?

    link_to "Uploaded file: #{file.identifier}", file.url, options.merge(target: '_blank')
  end
end

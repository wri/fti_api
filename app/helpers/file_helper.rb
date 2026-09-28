module FileHelper
  def preview_file_tag(file, options = {})
    return if file.identifier.blank?

    name = I18n.t("active_admin.shared.uploaded_file", file_name: file.identifier)
    name += " (Missing file)" unless file.exists?
    link_to name, file.url, options.merge(target: "_blank")
  end
end

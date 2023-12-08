class EsriShapefileZipInput < Formtastic::Inputs::FileInput
  def input_html_options
    {accept: ".zip"}.merge(super)
  end

  def hint_html
    builder.template.content_tag(:div) do
      I18n.t("active_admin.esri_shapefile_zip_input.hint").split('\n').map do |line|
        builder.template.content_tag(:p, line, class: "form-input-hint")
      end.join.html_safe
    end
  end
end

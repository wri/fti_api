# frozen_string_literal: true

ActiveAdmin.register ProtectedArea do
  extend BackRedirectable

  menu false

  permit_params [:name, :country_id, :esri_shapefiles_zip, :geojson, :wdpa_pid]

  filter :wdpa_pid
  filter :name
  filter :country,
    as: :select,
    collection: -> { Country.active.with_translations(I18n.locale) }

  index do
    column :id
    column :wdpa_pid
    column :country
    column :name

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    columns class: "d-flex" do
      column max_width: "500px" do
        f.inputs I18n.t("active_admin.details", model: I18n.t("activerecord.models.protected_area")) do
          f.input :wdpa_pid
          f.input :country
          f.input :name
        end
      end

      column class: "flex-1" do
        f.inputs ProtectedArea.human_attribute_name(:geometry) do
          f.input :esri_shapefiles_zip, as: :esri_shapefile_zip
          render partial: "upload_geometry_map",
            locals: {
              file_input_id: "protected_area_esri_shapefiles_zip",
              geojson: f.resource.geojson,
              bbox: f.resource.bbox,
              present: f.resource.geojson.present?,
              host: Rails.env.development? ? request.base_url : request.base_url + "/api",
              show_fmus: false,
              api_key: ENV["API_KEY"]
            }
        end
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :wdpa_pid
      row :name
      row :country
      row :map do |r|
        render partial: "map", locals: {center: [r.centroid.x, r.centroid.y], center_marker: false, geojson: r.geojson, bbox: r.bbox}
      end
      row :geojson do |r|
        r.geojson.to_json
      end
    end
  end
end

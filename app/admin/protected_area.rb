# frozen_string_literal: true

ActiveAdmin.register ProtectedArea do
  extend BackRedirectable

  menu false

  permit_params [:name, :country_id, :geojson, :wdpa_pid]

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
    f.inputs do
      f.input :wdpa_pid
      f.input :country
      f.input :name
      f.input :geojson, input_html: {value: f.object.geojson.to_json}

      f.actions
    end
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
    active_admin_comments
  end
end

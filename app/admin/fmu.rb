# frozen_string_literal: true

ActiveAdmin.register Fmu do
  extend BackRedirectable
  extend Versionable

  menu false

  active_admin_paranoia

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes(:country, :operator)
    end
  end

  scope -> { I18n.t("active_admin.all") }, :all, default: true
  scope -> { I18n.t("active_admin.free") }, :filter_by_free_aa

  permit_params :id, :name, :certification_fsc, :certification_pefc,
    :certification_olb, :certification_pafc, :certification_fsc_cw, :certification_tlv,
    :certification_ls, :esri_shapefiles_zip, :forest_type, :country_id,
    fmu_operator_attributes: [:id, :operator_id, :start_date, :end_date]

  filter :id, as: :select
  filter :country, as: :select, label: proc { I18n.t("activerecord.models.country.one") }, collection: -> { Country.joins(:fmus).by_name_asc }
  filter :operator_in_all, as: :select, label: proc { I18n.t("activerecord.attributes.fmu.operator") }, collection: -> { Operator.order(:name) }
  filter :name_cont,
    as: :select, label: proc { I18n.t("activerecord.attributes.fmu.name") },
    collection: -> { Fmu.by_name_asc.pluck(:name) }

  dependent_filters do
    {
      country_id: {
        operator_in_all: Operator.pluck(:country_id, :id)
      },
      operator_in_all: {
        name_cont: Operator.joins(:fmus).pluck(:id, "fmus.name")
      }
    }
  end

  csv do
    column :id
    column :name
    column I18n.t("activerecord.models.country.one") do |fmu|
      fmu.country&.name
    end
    column I18n.t("activerecord.models.operator") do |fmu|
      fmu.operator&.name
    end
    column :certification_fsc
    column :certification_pefc
    column :certification_olb
    column :certification_pafc
    column :certification_fsc_cw
    column :certification_tlv
    column :certification_ls
  end

  show do
    attributes_table do
      row :id
      row :name
      row :forest_type
      row :country
      row :operator
      row :certification_fsc
      row :certification_pefc
      row :certification_olb
      row :certification_pafc
      row :certification_fsc_cw
      row :certification_tlv
      row :certification_ls
      if resource.geojson && resource.centroid.present?
        row :map do |r|
          render partial: "map", locals: {center: [r.centroid.x, r.centroid.y], center_marker: false, geojson: r.geojson, bbox: r.bbox}
        end
      end
      row(:geojson) { |fmu| fmu.geojson.to_json }
      row(:properties) { |fmu| fmu.geojson&.dig("properties")&.to_json }
      row :created_at
      row :updated_at
      row :deleted_at
    end
  end

  index do
    column :id, sortable: true
    column :name, sortable: true
    column :country, sortable: "country_translations.name"
    column :operator
    column "FSC", :certification_fsc
    column "PEFC", :certification_pefc
    column "OLB", :certification_olb
    column "PAFC", :certification_pafc
    column "FSC CW", :certification_fsc_cw
    column "TLV", :certification_tlv
    column "LS", :certification_ls

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    columns class: "d-flex" do
      column max_width: "500px" do
        f.inputs I18n.t("active_admin.shared.fmu_details") do
          f.input :name
          f.input :country, input_html: {disabled: object.persisted?}, required: true
          f.input :forest_type, as: :select,
            collection: ForestType::TYPES.map { |key, v| [v[:label], key] },
            input_html: {disabled: object.persisted?}
          f.input :certification_fsc
          f.input :certification_pefc
          f.input :certification_olb
          f.input :certification_pafc
          f.input :certification_fsc_cw
          f.input :certification_tlv
          f.input :certification_ls
        end

        f.inputs I18n.t("activerecord.models.operator"), for: [:fmu_operator, f.object.fmu_operator || FmuOperator.new] do |fo|
          fo.input :operator_id, label: I18n.t("activerecord.attributes.operator.name"), as: :select,
            collection: Operator.active.map { |o| [o.name, o.id] },
            input_html: {disabled: object.persisted?}, required: false
          fo.input :start_date, input_html: {disabled: object.persisted?}, required: false
          fo.input :end_date, input_html: {disabled: object.persisted?}
        end
      end

      column class: "flex-1" do
        f.inputs Fmu.human_attribute_name(:geometry) do
          f.input :esri_shapefiles_zip, as: :esri_shapefile_zip

          render partial: "upload_geometry_map",
            locals: {
              file_input_id: "fmu_esri_shapefiles_zip",
              geojson: f.resource.geojson,
              bbox: f.resource.bbox,
              present: f.resource.geojson.present?,
              host: Rails.env.development? ? request.base_url : request.base_url + "/api",
              show_fmus: true,
              api_key: ENV["API_KEY"]
            }
        end
      end
    end

    f.actions
  end
end

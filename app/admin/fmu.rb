# frozen_string_literal: true

ActiveAdmin.register Fmu do
  extend BackRedirectable
  extend Versionable

  controller do
    def scoped_collection
      end_of_association_chain.includes(:country, :operator)
    end

    def download_shapefiles(fmus)
      file_content = ShapefileService.generate_shapefile(fmus)

      filename = "fmus"
      filename = fmus.first&.name if fmus.size == 1
      filename = filename.gsub(/[^0-9A-Za-z ]/, "")[0..30]
      filename += ".zip"

      send_data file_content, type: "application/zip", filename: filename, disposition: "attachment"
    end
  end

  scope -> { I18n.t("active_admin.all") }, :all, default: true
  scope -> { I18n.t("active_admin.free") }, :filter_by_free_aa

  menu false

  active_admin_paranoia

  config.order_clause
  config.batch_actions = true

  batch_action :destroy, false
  batch_action :download_shapefiles do |ids|
    fmus = batch_action_collection.find(ids)
    download_shapefiles(fmus)
  end

  member_action :download_shapefile, method: :get do
    fmu = Fmu.find(params[:id])
    download_shapefiles([fmu])
  end

  action_item :download_shapefile, only: :show do
    link_to I18n.t("active_admin.fmus_page.download_shapefile"), download_shapefile_admin_fmu_path(fmu), method: :get
  end

  permit_params :id, :name,
    :certification_fsc, :certification_pefc, :certification_ls, :certification_pbn,
    :certification_olb, :certification_pafc, :certification_fsc_cw, :certification_tlv,
    :esri_shapefiles_zip, :forest_type, :country_id,
    fmu_operator_attributes: [:id, :operator_id, :start_date, :end_date]

  filter :id, as: :select
  filter :country, as: :select, label: proc { I18n.t("activerecord.models.country.one") }, collection: -> { Country.joins(:fmus).by_name_asc }
  filter :operator_in_all, as: :select, label: proc { Fmu.human_attribute_name(:operator) }, collection: -> { Operator.order(:name) }
  filter :name_cont,
    as: :select, label: proc { Fmu.human_attribute_name(:name) },
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

  sidebar "Shapefiles", only: :index do
    div do
      link_to "Download Filtered Shapefiles", download_filtered_shapefiles_admin_fmus_path(
        q: params[:q]&.to_unsafe_h
      ), class: "button text-center mt-10px"
    end
  end

  collection_action :download_filtered_shapefiles, method: :get do
    fmus = Fmu.ransack(params.dig(:q)).result(distinct: true)
    download_shapefiles(fmus)
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
    column :certification_pbn
    column :certification_fsc_cw
    column :certification_tlv
    column :certification_ls
  end

  show do
    columns class: "d-flex" do
      column class: "flex-1" do
        attributes_table do
          row :id
          row :name
          row :forest_type
          row :country
          row :operator

          if resource.geojson && resource.centroid.present?
            row :map do |r|
              render partial: "map", locals: {center: [r.centroid.x, r.centroid.y], center_marker: false, geojson: r.geojson, bbox: r.bbox}
            end
          end
          if resource.geojson
            row(:geojson) do
              dialog id: "geojson_modal", title: Fmu.human_attribute_name(:geojson) do
                resource.geojson
              end
              link_to t("active_admin.view"), "javascript:void(0)", onclick: "document.querySelector('#geojson_modal').showModal()"
            end
            row(:properties) do
              dialog id: "properties_modal", title: Fmu.human_attribute_name(:properties) do
                resource.properties
              end
              link_to t("active_admin.view"), "javascript:void(0)", onclick: "document.querySelector('#properties_modal').showModal()"
            end
          end
          row :created_at
          row :updated_at
          row :deleted_at
        end
      end

      column max_width: "250px" do
        attributes_table title: t("active_admin.fmus_page.certification") do
          row :certification_fsc
          row :certification_pefc
          row :certification_olb
          row :certification_pafc
          row :certification_fsc_cw
          row :certification_pbn
          row :certification_tlv
          row :certification_ls
        end
      end
    end
  end

  index do
    selectable_column
    column :id, sortable: true
    column :name, sortable: true
    column :country, sortable: "country_translations.name"
    column :operator
    column "FSC", :certification_fsc
    column "PEFC", :certification_pefc
    column "OLB", :certification_olb
    column "PAFC", :certification_pafc
    column "PbN", :certification_pbn
    column "FSC CW", :certification_fsc_cw
    column "TLV", :certification_tlv
    column "LS", :certification_ls

    actions defaults: false do |fmu|
      item I18n.t("active_admin.fmus_page.download_shapefile"), download_shapefile_admin_fmu_path(fmu), method: :get
      item I18n.t("active_admin.view"), admin_fmu_path(fmu)
      item I18n.t("active_admin.edit"), edit_admin_fmu_path(fmu)
      item I18n.t("active_admin.delete"), admin_fmu_path(fmu), method: :delete, data: {confirm: I18n.t("active_admin.fmus_page.confirm_delete")}
    end
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
          f.input :certification_pbn
          f.input :certification_tlv
          f.input :certification_ls
        end

        f.inputs I18n.t("activerecord.models.operator"), for: [:fmu_operator, f.object.fmu_operator || FmuOperator.new] do |fo|
          fo.input :operator_id, label: Operator.human_attribute_name(:name), as: :select,
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

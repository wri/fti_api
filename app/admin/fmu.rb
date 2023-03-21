# frozen_string_literal: true

ActiveAdmin.register Fmu do
  extend BackRedirectable
  extend Versionable

  menu false

  active_admin_paranoia

  config.order_clause

  MAX_FILE_SIZE = 200_000

  controller do
    def preview
      file = params['file']
      response = if file.blank? || file.size > MAX_FILE_SIZE
                   { errors: "File must exist and be smaller than #{MAX_FILE_SIZE/1000} KB" }
                 else
                   Fmu.file_upload(file)
      end
      respond_to do |format|
        format.json { render json: response }
      end
    end

    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale).includes(:country, :operator)
    end
  end

  scope I18n.t('active_admin.all'), :all, default: true
  scope I18n.t('active_admin.free'), :filter_by_free_aa

  permit_params :id, :certification_fsc, :certification_pefc,
                :certification_olb, :certification_pafc, :certification_fsc_cw, :certification_tlv,
                :certification_ls, :esri_shapefiles_zip, :forest_type, :country_id,
                fmu_operator_attributes: [:id, :operator_id, :start_date, :end_date],
                translations_attributes: [:id, :locale, :name, :_destroy]

  filter :id, as: :select
  filter :translations_name_contains,
         as: :select, label: I18n.t('activerecord.attributes.fmu/translation.name'),
         collection: -> { Fmu.by_name_asc.pluck(:name) }
  filter :country, as: :select, collection: -> { Country.joins(:fmus).by_name_asc }
  filter :operator_in_all, label: I18n.t('activerecord.attributes.fmu.operator'), as: :select, collection: -> { Operator.order(:name) }

  csv do
    column :id
    column :name
    column I18n.t('activerecord.models.country.one') do |fmu|
      fmu.country&.name
    end
    column I18n.t('activerecord.models.operator') do |fmu|
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
      row(:geojson) { |fmu| fmu.geojson.to_json }
      row(:properties) { |fmu| fmu.geojson&.dig('properties') }
      row :created_at
      row :updated_at
      row :deleted_at
    end
  end

  index do
    column :id, sortable: true
    column :name, sortable: 'fmu_translations.name'
    column :country, sortable: 'country_translations.name'
    column :operator
    column 'FSC', :certification_fsc
    column 'PEFC', :certification_pefc
    column 'OLB', :certification_olb
    column 'PAFC', :certification_pafc
    column 'FSC CW', :certification_fsc_cw
    column 'TLV', :certification_tlv
    column 'LS', :certification_ls

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.shared.fmu_details') do
      f.input :country,  input_html: { disabled: object.persisted? }, required: true
      f.input :esri_shapefiles_zip, as: :file, input_html: { accept: '.zip' }
      render partial: 'zip_hint'
      f.input :forest_type, as: :select,
                            collection: Fmu::FOREST_TYPES.map { |k, h| [h[:label], k] },
                            input_html: { disabled: object.persisted? }
      f.input :certification_fsc
      f.input :certification_pefc
      f.input :certification_olb
      f.input :certification_pafc
      f.input :certification_fsc_cw
      f.input :certification_tlv
      f.input :certification_ls
    end

    f.inputs I18n.t('activerecord.models.operator'), for: [:fmu_operator, f.object.fmu_operator || FmuOperator.new] do |fo|
      fo.input :operator_id, label: I18n.t('activerecord.attributes.fmu/translation.name'), as: :select,
                             collection: Operator.active.map{ |o| [o.name, o.id] },
                             input_html: { disabled: object.persisted? }, required: false
      fo.input :start_date, input_html: { disabled: object.persisted? }, required: false
      fo.input :end_date, input_html: { disabled: object.persisted? }
    end

    f.inputs I18n.t('active_admin.shared.translated_fields') do
      f.translated_inputs switch_locale: false do |t|
        t.input :name, label: I18n.t('activerecord.attributes.fmu/translation.name')
      end
    end
    f.actions

    render partial: 'form',
           locals: {
             geojson: f.resource.geojson,
             bbox: f.resource.bbox,
             present: f.resource.geojson.present?,
             host: Rails.env.development? ? request.base_url : request.base_url + '/api' ,
             api_key: ENV['API_KEY']
           }
  end
end

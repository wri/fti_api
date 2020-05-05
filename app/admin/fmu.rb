# frozen_string_literal: true

ActiveAdmin.register Fmu do
  extend BackRedirectable
  back_redirect

  menu false

  active_admin_paranoia

  config.order_clause

  controller do
    def preview
      response = Fmu.file_upload(params['file'])
      respond_to do |format|
        format.json { render json: response }
      end
    end

    def scoped_collection
      end_of_association_chain.with_translations.includes(country: :translations)
        .where(country_translations: { locale: I18n.locale })
    end
  end

  scope :all, default: true
  scope 'Free', :filter_by_free_aa

  permit_params :id, :certification_fsc, :certification_pefc,
                :certification_olb, :certification_pafc, :certification_fsc_cw, :certification_tlv,
                :certification_ls, :esri_shapefiles_zip, :country_id,
                translations_attributes: [:id, :locale, :name, :_destroy]

  filter :id, as: :select
  filter :translations_name_contains,
         as: :select, label: 'Name',
         collection: -> { Fmu.with_translations(I18n.locale).order('fmu_translations.name').pluck(:name) }
  filter :country, as: :select,
                   collection: -> { Country.joins(:fmus).with_translations(I18n.locale).order('country_translations.name') }
  filter :operator_in_all, label: 'Operator', as: :select,
                           collection: -> { Operator.with_translations(I18n.locale).order('operator_translations.name') }

  csv do
    column :id
    column :name
    column 'country' do |fmu|
      fmu.country&.name
    end
    column 'operator' do |fmu|
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
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Fmu Details' do
      f.input :country,  input_html: { disabled: object.persisted? }
      f.input :esri_shapefiles_zip, as: :file, input_html: { accept: '.zip' }
      # TODO This needs a better approach
      f.has_many :operators, new_record: false do |o|
        o.input :name, input_html: { disabled: true }
      end
      f.input :certification_fsc
      f.input :certification_pefc
      f.input :certification_olb
      f.input :certification_pafc
      f.input :certification_fsc_cw
      f.input :certification_tlv
      f.input :certification_ls
    end

    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end
    f.actions

    render partial: 'form',
           locals: {
             geojson: f.resource.geojson,
             bbox: f.resource.bbox,
             present: f.resource.geojson.present?
           }
  end
end

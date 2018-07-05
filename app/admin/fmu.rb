# frozen_string_literal: true

ActiveAdmin.register Fmu do
  menu false

  actions :show, :edit, :index, :update

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [country: :translations]])
    end
  end

  scope :all, default: true
  scope 'Free', :filter_by_free

  permit_params :id, :certification_fsc, :certification_pefc,
                :certification_olb, :certification_vlc, :certification_vlo, :certification_tltv,
                translations_attributes: [:id, :locale, :name, :_destroy]

  filter :id, as: :select
  filter :translations_name_contains,
         as: :select, label: 'Name',
         collection: Fmu.with_translations(I18n.locale).order('fmu_translations.name').pluck(:name)
  filter :country, as: :select, collection:
      Country.joins(:fmus).with_translations(I18n.locale)
          .order('country_translations.name')
  filter :operator_in_all, label: 'Operator', as: :select,
         collection: -> { Operator.with_translations(I18n.locale).order('operator_translations.name')}

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
    column :certification_vlc
    column :certification_vlo
    column :certification_tltv
  end

  index do
    column :id, sortable: true
    column :name, sortable: 'fmu_translations.name'
    column :country, sortable: 'country_translations.name'
    column :operator
    column 'FSC', :certification_fsc
    column 'PEFC', :certification_pefc
    column 'OLB', :certification_olb
    column 'VLC', :certification_vlc
    column 'VLO', :certification_vlo
    column 'TLTV', :certification_tltv

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Fmu Details' do
      f.input :country,  input_html: { disabled: true }
      # TODO This needs a better approach
      f.has_many :operators, new_record: false do |o|
        o.input :name, input_html: { disabled: true }
      end
      f.input :certification_fsc
      f.input :certification_pefc
      f.input :certification_olb
      f.input :certification_vlc
      f.input :certification_vlo
      f.input :certification_tltv
    end

    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end

    f.actions
  end
end

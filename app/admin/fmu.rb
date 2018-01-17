# frozen_string_literal: true

ActiveAdmin.register Fmu do
  # menu parent: 'Settings', priority: 5
  menu false

  actions :show, :edit, :index, :update

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [country: :translations],
                                         [fmu_operators: [operator: :translations]]])
    end
  end

  scope :all, default: true
  scope 'Free', :filter_by_free

  permit_params :id, :certification_fsc, :certification_pefc,
                :certification_olb, translations_attributes: [:id, :locale, :name, :_destroy]

  filter :id, as: :select
  filter :translations_name_contains, as: :select, label: 'Name',
                                      collection: Fmu.joins(:translations).pluck(:name)
  filter :country

  index do
    column :id, sortable: true
    column :name, sortable: 'fmu_translations.name'
    column :country, sortable: 'country_translations.name'
    column :operator, sortable: 'operator_translations.name'
    column :certification_fsc
    column :certification_pefc
    column :certification_olb

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Fmu Details' do
      f.input :country,  input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }
      f.input :certification_fsc
      f.input :certification_pefc
      f.input :certification_olb
    end

    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end

    f.actions
  end
end

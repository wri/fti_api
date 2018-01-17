# frozen_string_literal: true

ActiveAdmin.register Law do
  # menu parent: 'Settings', priority: 4
  menu false

  actions :new, :create, :show, :edit, :index, :update, :destroy

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([[country: :translations],
                                         [subcategory: :translations]])
    end
  end

  permit_params :id, :subcategory_id, :infraction, :sanctions, :min_fine, :max_fine, :penal_servitude,
                :other_penalties, :apv, :written_infraction, :country_id

  filter :country
  filter :subcategory
  filter :written_infraction, label: 'Illegality as written by law', as: :select
  filter :infraction, label: 'Legal reference: Illegality', as: :select
  filter :sanctions, label: 'Legal reference: Penalties', as: :select
  filter :max_fine, label: 'Maximum Fine'
  filter :min_fine, label: 'Minimum Fine'

  index do
    column :country, sortable: 'country_translations.name'
    column :subcategory, sortable: 'subcategory_translations.name'
    column 'Illegality as written by law', :written_infraction, sortable: true
    column 'Legal reference: Illegality', :infraction, sortable: true
    column 'Legal reference: Penalties', :sanctions, sortable: true
    column 'Minimum fine', :min_fine, sortable: true
    column 'Maximum fine', :max_fine, sortable: true
    column :penal_servitude, sortable: true
    column :other_penalties, sortable: true
    column 'Indicator APV', :apv, sortable: true
    column :created_at, sortable: true
    column :updated_at, sortable: true

    actions

  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Law Details' do
      if f.object.new_record?
        f.input :country
        f.input :subcategory, as: :select,
                              collection: Subcategory.operator.with_translations(I18n.locale).order(:name)
      else
        f.input :country, input_html: { disabled: true }
        f.input :subcategory, input_html: { disabled: true }
      end

      f.input :written_infraction, label: 'Illegality as written by law'
      f.input :infraction,         label: 'Legal reference: Illegality'
      f.input :sanctions,          label: 'Legal reference: Penalties'
      f.input :min_fine,           label: 'Minimum Fine'
      f.input :max_fine,           label: 'Maximum Fine'
      f.input :penal_servitude
      f.input :other_penalties
      f.input :apv, label: 'Indicateur APV'

      f.actions
    end
  end
end

# frozen_string_literal: true

ActiveAdmin.register Country do
  extend BackRedirectable

  menu false

  actions :show, :index, :edit, :update, :create

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.with_translations
    end
  end

  scope I18n.t('active_admin.all'), :all
  scope I18n.t('active_admin.shared.active'), :active

  filter :iso, as: :select
  filter :translations_name_contains, as: :select,
                                      label: I18n.t('activerecord.attributes.country.name'),
                                      collection: -> { Country.order(:name).pluck(:name) }
  filter :region_iso, as: :select
  filter :region_name
  filter :is_active

  permit_params translations_attributes: [:id, :locale, :name, :_destroy]

  csv do
    column :is_active
    column :id
    column :iso
    column :name
    column :region_iso
    column :region_name
  end

  index do
    column :is_active, sortable: true
    column :id, sortable: true
    column :iso, sortable: true
    column :name, sortable: 'country_translations.name'
    column :region_iso, sortable: true
    column :region_name, sortable: 'country_translations.region_name'

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs I18n.t('active_admin.shared.country_details') do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end

      f.actions
    end
  end

  show do
    attributes_table do
      row :name
      row :iso
      row :region_iso
      row :is_active
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

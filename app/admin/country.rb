# frozen_string_literal: true

ActiveAdmin.register Country do
  #menu parent: 'Settings', priority: 6
  menu false

  actions :show, :index, :edit, :update

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end

  scope :all
  scope :active

  filter :iso, as: :select
  filter :translations_name_contains, as: :select, label: 'Name',
                                      collection: Country.order(:name).pluck(:name)
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
    column 'Active?', :is_active, sortable: true
    column :id, sortable: true
    column :iso, sortable: true
    column :name, sortable: 'country_translations.name'
    column :region_iso, sortable: true
    column :region_name, sortable: 'country_translations.region_name'

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Country Details' do
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

# frozen_string_literal: true

ActiveAdmin.register CountryLink do
  extend BackRedirectable

  menu false

  config.order_clause

  permit_params :active, :position, :url, :country_id, translations_attributes: [:id, :locale, :name, :description, :_destroy]

  filter :position, as: :select
  filter :country

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale).includes(country: :translations)
    end
  end

  index do
    column :id
    column :active
    column :country
    column :position
    column :name
    column :description
    column :url
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Country Links Details" do
      f.input :country
      f.input :active
      f.input :position
      f.input :url
    end
    f.translated_inputs "Translations", switch_locale: false do |t|
      t.input :name
      t.input :description
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :active
      row :country
      row :position
      row :url
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

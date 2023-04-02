# frozen_string_literal: true

ActiveAdmin.register Donor do
  extend BackRedirectable

  menu false

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end

  permit_params :website, :logo, :priority, :category, translations_attributes: [:id, :locale, :name, :description]

  filter :translations_name_contains, as: :select, label: I18n.t('activerecord.attributes.donor.name'),
                                      collection: -> { Donor.with_translations(I18n.locale).pluck(:name) }
  filter :website, as: :select

  csv do
    column :name
    column :website
    column :priority
    column :description
  end

  index do
    column :name
    column :website
    column :logo do |d|
      link_to d.logo&.identifier, d.logo&.url if d.logo&.url
    end
    column :priority
    column :description

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
        t.input :description
      end
    end
    f.inputs 'Donor Details' do
      f.input :website
      f.input :priority
      f.input :logo
    end
    f.actions
  end


  show do
    attributes_table do
      row :name
      row :website
      row :logo do |d|
        link_to d.logo&.identifier, d.logo&.url if d.logo&.url
      end
      row :priority
      row :description
      row :created_at
      row :updated_at
    end
    active_admin_comments

  end
end

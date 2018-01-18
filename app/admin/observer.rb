# frozen_string_literal: true

ActiveAdmin.register Observer, as: 'Monitor' do
  menu false

  config.order_clause

  actions :all

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [countries: :translations]])
    end
  end

  permit_params :observer_type, :is_active, :logo, :address, :information_name, :information_email,
                :information_phone, :data_name, :data_email, :data_phone, :organization_type,
                translations_attributes: [:id, :locale, :name, :_destroy], country_ids: []

  index do
    column :is_active
    column :countries do |observer|
      links =[]
      observer.countries.each do |country|
        links << link_to(country.name, admin_country_path(country.id))
      end
      links.join(' ').html_safe
    end
    column :observer_type, sortable: true
    image_column :logo
    column :name, sortable: 'observer_translations.name'
    column :created_at
    column :updated_at
    actions
  end

  filter :is_active
  filter :countries, collection: Country.joins(:translations).order(:name).pluck(:name)
  filter :translations_name_contains, as: :select, label: 'Name',
                                      collection: Observer.joins(:translations).pluck(:name)


  show do
    attributes_table do
      row :is_active
      row :observer_type
      row :organization_type
      row :countries do |observer|
        links =[]
        observer.countries.each do |country|
          links << link_to(country.name, admin_country_path(country.id))
        end
        links.join(' ').html_safe
      end
      image_row :logo
      row :address
      row :information_name
      row :information_email
      row :information_phone
      row :data_name
      row :data_email
      row :data_phone
      row :created_at
      row :updated_at

    end
    active_admin_comments
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end
    f.inputs 'Monitor Details' do
      f.input :countries
      f.input :observer_type, as: :select, collection: %w(Mandated SemiMandated External Government)
      f.input :organization_type, as: :select, collection: ['NGO', 'Academic', 'Research Institute', 'Private Company', 'Other']
      f.input :logo
      f.input :address
      f.input :information_name
      f.input :information_email
      f.input :information_phone
      f.input :data_name
      f.input :data_email
      f.input :data_phone
      f.input :is_active
    end
    f.actions
  end
end

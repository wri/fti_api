# frozen_string_literal: true

ActiveAdmin.register Donor do
  menu false
  permit_params :website, :logo, :priority, :category, translations_attributes: [:id, :locale, :name, :description]

  filter :translations_name_contains, as: :select, label: 'Name',
                                      collection: Partner.joins(:translations).pluck(:name)
  filter :website, as: :select


  index do
    column :name
    column :website
    image_column :logo
    column :priority
    column :description

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
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
      image_row :logo
      row :priority
      row :description
      row :created_at
      row :updated_at
    end
    active_admin_comments

  end
end
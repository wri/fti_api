# frozen_string_literal: true
ActiveAdmin.register Partner do
  menu parent: 'User Management', priority: 4
  permit_params :name, :website, :logo, :priority, :category, :description

  filter :name, as: :select
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
    f.inputs 'Partner Details' do

      f.input :name
      f.input :website
      f.input :logo
      f.input :priority
      f.input :description
    end
    f.actions
  end


  show do

  end
end

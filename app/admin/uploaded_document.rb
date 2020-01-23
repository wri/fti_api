# frozen_string_literal: true

ActiveAdmin.register UploadedDocument do
  extend BackRedirectable
  back_redirect

  menu false

  config.order_clause


  permit_params :file, :name, :author, :caption

  filter :name
  filter :author

  index do
    column :name
    column :author
    column :caption
    column :file_url
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Uploaded Document Details' do
      f.input :name
      f.input :author
      f.input :caption
      f.input :file, as: :file
    end
    f.actions
  end


  show do
    attributes_table do
      row :name
      row :author
      row :caption
      row :file
    end
    active_admin_comments
  end

end

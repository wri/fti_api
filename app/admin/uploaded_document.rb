# frozen_string_literal: true

ActiveAdmin.register UploadedDocument do
  extend BackRedirectable

  menu false

  config.order_clause

  permit_params :file, :name, :author, :caption

  filter :name
  filter :author

  index do
    column :name
    column :author
    column :caption
    column :file do |d|
      link_to d.file.url, d.file.url
    end
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Uploaded Document Details" do
      f.input :name
      f.input :author
      f.input :caption
      f.input :file, as: :file, hint: preview_file_tag(f.object.file)
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :author
      row :caption
      row :file do |d|
        link_to d.file.url, d.file.url
      end
    end
  end
end

# frozen_string_literal: true

ActiveAdmin.register Tutorial do
  menu false

  config.order_clause


  permit_params :position, :name, :description

  filter :position, as: :select
  filter :name

  index do
    column :position
    column :name
    column :description

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Tutorial Details' do
      f.input :position
      f.input :name
      f.input :description,
              as: :quill_editor,
              input_html: {
                  data: {
                      options: {
                          modules: {
                              toolbar: [['bold', 'italic', 'underline'],
                                        ['link', 'video']]
                          },
                          placeholder: 'Type something...',
                          theme: 'snow'
                      }}}
    end
    f.actions
  end


  show do
    attributes_table do
      row :position
      row :name
      row :description
    end

    active_admin_comments
  end

end

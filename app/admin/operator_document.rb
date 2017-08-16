ActiveAdmin.register OperatorDocument do
  menu parent: 'Documents', priority: 2

  actions :all, except: [:destroy, :new, :create]
  permit_params :name, :required_operator_document_id,
                :operator_id, :type, :status, :expire_date, :start_date,
                :attachment

  index do
    tag_column :status
    column :required_operator_document
    column :operator
    column :type
    column :expire_date
    column :start_date
    attachment_column :attachment


    actions
  end

  filter :required_operator_document
  filter :operator
  filter :type
  filter :status
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Operator Document Details' do
      f.input :required_operator_document, input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }
      f.input :type, input_html: { disabled: true }
      f.input :status, include_blank: false
      f.input :attachment
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker
    end
    f.actions
  end

  show do
    attributes_table do
      row :required_operator_document
      row :operator
      row :status
      row :fmu, unless: resource.fmu.blank?
      row :current
      attachment_row('Attachment', :attachment, label: "#{resource.attachment.file.filename}", truncate: false)
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end
end
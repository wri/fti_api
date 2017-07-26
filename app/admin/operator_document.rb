ActiveAdmin.register OperatorDocument do
  menu parent: 'Documents', priority: 2

  actions :all, except: [:destroy, :new, :create]
  permit_params :name, :required_operator_document_id,
                :operator_id, :type, :status, :expire_date, :start_date,
                documents_attributes: [:id, :name, :document_type, :attachment]

  index do
    column :required_operator_document
    column :operator
    column :type
    column :expire_date
    column :start_date
    column :status

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
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker


      f.has_many :documents, allow_destroy: false, new_record: true, heading: 'Documents' do |d|
        d.input :name
        d.input :document_type, collection: %w(Report Doumentation), include_blank: false
        d.input :attachment
      end
    end
    f.actions
  end
end
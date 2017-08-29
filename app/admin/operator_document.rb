ActiveAdmin.register OperatorDocument do
  menu parent: 'Documents', priority: 2
  config.order_clause

  active_admin_paranoia

  scope_to do
    Class.new do
      def self.operator_documents
        OperatorDocument.unscoped
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:required_operator_document, :user, [operator: :translations],
                                        [fmu: :translations], [required_operator_document: [required_operator_document_group: :translations]]])
    end
  end

  member_action :approve, method: :put do
    resource.update_attributes(status: OperatorDocument.statuses[:doc_valid])
    redirect_to collection_path, notice: 'Document approved'
  end

  member_action :reject, method: :put do
    resource.update_attributes(status: OperatorDocument.statuses[:doc_invalid])
    redirect_to collection_path, notice: 'Document rejected'
  end

  actions :all, except: [:destroy, :new, :create]
  permit_params :name, :required_operator_document_id,
                :operator_id, :type, :status, :expire_date, :start_date,
                :attachment, :uploaded_by

  index do
    tag_column :status
    column :required_operator_document, sortable: 'required_operator_documents.name'
    column :'Type', sortable: 'required_operator_documents.type' do |od|
      od.required_operator_document.type
    end
    column :operator, sortable: 'operator_translations.name'
    column :fmu, sortable: 'fmu_translations.name'
    column 'Legal Category' do |od|
      od.required_operator_document.required_operator_document_group.name
    end
    column :user, sortable: 'users.name'
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    attachment_column :attachment
    column('Approve') { |observation| link_to 'Approve', approve_admin_operator_document_path(observation), method: :put}
    column('Reject') { |observation| link_to 'Reject', reject_admin_operator_document_path(observation), method: :put}
    actions
  end

  filter :required_operator_document
  filter :operator
  filter :status
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Operator Document Details' do
      f.input :required_operator_document, input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }
      f.input :type, input_html: { disabled: true }
      f.input :uploaded_by
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
      row :fmu, unless: resource.is_a?(OperatorDocumentCountry)
      row :uploaded_by
      row :current
      if resource.attachment.present?
        attachment_row('Attachment', :attachment, label: "#{resource.attachment.file.filename}", truncate: false)
      end
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end
end
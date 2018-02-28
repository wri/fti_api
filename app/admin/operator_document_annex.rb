# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentAnnex do
  menu false
  config.order_clause

  active_admin_paranoia

  # To include the deleted operator document annexes
  scope_to do
    Class.new do
      def self.operator_document_annexes
        OperatorDocumentAnnex.unscoped
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:user, [operator_document: [operator: :translations, required_operator_document: :translations]]])
    end
  end

  member_action :approve, method: :put do
    if resource.update_attributes(status: OperatorDocumentAnnex.statuses[:doc_valid])
      redirect_to collection_path, notice: 'Annex approved'
    else
      redirect_to collection_path, alert: 'Annex could not be approved'
    end
  end

  member_action :reject, method: :put do
    if resource.update_attributes(status: OperatorDocumentAnnex.statuses[:doc_invalid])
      redirect_to collection_path, notice: 'Annex rejected'
    else
      redirect_to collection_path, alert: 'Annex could not be rejected'
    end
  end

  actions :all, except: [:destroy, :new, :create]
  permit_params :name, :operator_document_id, :status, :expire_date, :start_date,
                :attachment, :uploaded_by

  index do
    bool_column :exists do |od|
      od.deleted_at.nil?
    end
    tag_column :status
    column :operator_document, sortable: 'required_operator_documents.name' do |od|
      if od.operator_document.present? && od.operator_document.required_operator_document.present?
        od.operator_document.required_operator_document.name
      else
        OperatorDocument.unscoped.find(od.operator_document_id).required_operator_document.name
      end
    end
    column :operator, sortable: 'operator_translations.name' do |od|
      if od.operator_document.present? && od.operator_document.operator.present?
        od.operator_document.operator.name
      else
        OperatorDocument.unscoped.find(od.operator_document_id).operator.name
      end
    end

    column :user, sortable: 'users.name'
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    attachment_column :attachment
    column('Approve') { |annex| link_to 'Approve', approve_admin_operator_document_annex_path(annex), method: :put}
    column('Reject') { |annex| link_to 'Reject', reject_admin_operator_document_annex_path(annex), method: :put}
    actions
  end


  filter :operator_document, as: :select, collection: OperatorDocument.pluck(:id)
  filter :operator
  filter :status, as: :select, collection: OperatorDocumentAnnex.statuses
  filter :updated_at

  scope 'Pending', :doc_pending

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Operator Document Annex Details' do
      f.input :operator_document, as: :select, collection: OperatorDocument.pluck(:id), input_html: { disabled: true }
      f.input :uploaded_by
      f.input :name
      f.input :status, include_blank: false
      f.input :attachment
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker
    end
    f.actions
  end

  show  do
    attributes_table do
      tag_row :status
      row :required_operator_document do
        resource.operator_document.required_operator_document if resource.operator_document.present? &&
            resource.operator_document.required_operator_document.present?
      end
      row :operator do
        resource.operator_document.operator if resource.operator_document.present?
      end
      row :operator_document
      row :uploaded_by
      row :user
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

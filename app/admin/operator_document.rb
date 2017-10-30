ActiveAdmin.register OperatorDocument do
  menu parent: 'Operator Documents', priority: 2
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
    if resource.reason.present?
      resource.update_attributes(status: OperatorDocument.statuses[:doc_not_required])
    else
      resource.update_attributes(status: OperatorDocument.statuses[:doc_valid])
    end
    redirect_to collection_path, notice: 'Document approved'
  end

  member_action :reject, method: :put do
    resource.update_attributes(status: OperatorDocument.statuses[:doc_invalid], reason: nil)
    resource.remove_attachment!
    redirect_to collection_path, notice: 'Document rejected'
  end

  sidebar 'Annexes', only: :show do
    attributes_table_for resource do
      ul do
        resource.operator_document_annexes.collect do |annex|
          li link_to(annex.name, admin_operator_document_annex_path(annex.id))
        end
      end
    end
  end

  actions :all, except: [:destroy, :new, :create]
  permit_params :name, :required_operator_document_id,
                :operator_id, :type, :status, :expire_date, :start_date,
                :attachment, :uploaded_by, :reason

  index do
    bool_column :exists do |od|
      od.deleted_at.nil?
    end
    tag_column :status
    column :id
    column 'Required Document', :required_operator_document, sortable: 'required_operator_documents.name' do |od|
      if od.required_operator_document.present?
        link_to od.required_operator_document.name, admin_required_operator_document_path(od.required_operator_document)
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).name
      end
    end
    column :'Type', sortable: 'required_operator_documents.type' do |od|
      if od.required_operator_document.present?
        od.required_operator_document.type == 'RequiredOperatorDocumentFmu' ? 'Fmu' : 'Operator'
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).type
      end
    end
    column :operator, sortable: 'operator_translations.name'
    column :fmu, sortable: 'fmu_translations.name'
    column 'Legal Category' do |od|
      if od.required_operator_document.present?
        od.required_operator_document.required_operator_document_group.name
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).required_operator_document_group.name
      end
    end
    column :user, sortable: 'users.name'
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    attachment_column :attachment
    column :reason
    column('Approve') { |observation| link_to 'Approve', approve_admin_operator_document_path(observation), method: :put}
    column('Reject') { |observation| link_to 'Reject', reject_admin_operator_document_path(observation), method: :put}
    actions
  end


  filter :id, as: :select
  filter :required_operator_document,
         collection: RequiredOperatorDocument.
             joins(country: :translations).all.map {|x| ["#{x.name} - #{x.country.name}", x.id]}
  filter :operator
  filter :status, as: :select, collection: OperatorDocument.statuses
  filter :type, as: :select
  filter :updated_at

  scope 'Pending', :doc_pending

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Operator Document Details' do
      f.input :required_operator_document, input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }
      f.input :type, input_html: { disabled: true }
      f.input :uploaded_by
      f.input :status, include_blank: false
      f.input :attachment
      f.input :reason
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker
    end
    f.actions
  end

  show title: proc{ "#{resource.operator.name} - #{resource.required_operator_document.name}" } do
    attributes_table do
      row :current
      tag_row :status
      row :required_operator_document
      row :operator
      row :fmu, unless: resource.is_a?(OperatorDocumentCountry)
      row :uploaded_by
      if resource.attachment.present?
        attachment_row('Attachment', :attachment, label: "#{resource.attachment.file.filename}", truncate: false)
      end
      row :reason
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end
end
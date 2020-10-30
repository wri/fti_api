# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentAnnex do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  menu false
  config.order_clause

  active_admin_paranoia

  # To include the deleted operator document annexes
  scope_to do
    Class.new do
      def self.operator_document_annexes
        OperatorDocumentAnnex.unscoped.uniq
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:user, annex_documents: [documentable: [operator: :translations, required_operator_document: :translations]]])
    end
  end

  member_action :approve, method: :put do
    if resource.update(status: OperatorDocumentAnnex.statuses[:doc_valid])
      redirect_to collection_path, notice: 'Annex approved'
    else
      redirect_to collection_path, alert: 'Annex could not be approved'
    end
  end

  member_action :reject, method: :put do
    if resource.update(status: OperatorDocumentAnnex.statuses[:doc_invalid])
      redirect_to collection_path, notice: 'Annex rejected'
    else
      redirect_to collection_path, alert: 'Annex could not be rejected'
    end
  end

  actions :all, except: [:destroy, :new]
  permit_params :name, :status, :expire_date, :start_date,
                :attachment, :uploaded_by

  csv do
    column 'exists' do |annex|
      annex.deleted_at.nil?
    end
    column :status

    column 'documents' do |annex|
      documents = []
      annex.annex_documents.each do |ad|
        documents << ad.documentable
      end
      documents.split(' ')
    end
    column 'operator' do |annex|
      annex.annex_documents.first&.documentable&.operator&.name
    end

    column 'user' do |annex|
      annex.user&.name
    end
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
  end

  index do
    bool_column :exists do |od|
      od.deleted_at.nil?
    end
    tag_column :status
    column :operator_documents do |od|
      doc = OperatorDocument.unscoped.find(annex_document.documentable_id)
      link_to(doc.required_operator_document.name, admin_operator_document_path(doc.id))
    end
    column :operator_documents_history do |od|
      od.annex_documents_history.each_with_object([]) do |ad, links|
        doc = OperatorDocumentHistory.unscoped.find(ad.documentable_id)
        links << link_to(doc.required_operator_document.name, admin_operator_document_history_path(doc.id))
      end.reduce(:+)
    end
    column :operator, sortable: 'operator_translations.name' do |od|
      begin
        o = od.annex_documents_history.first.documentable.operator
        link_to(o.name, admin_producer_path(o.id))
      rescue
      end
    end
    column :fmu, sortable: 'fmu_translations.name' do |od|
      doc = od.annex_documents.first
      fmu = doc.documentable_type.constantize.unscoped.find(doc.documentable_id).fmu
      link_to(fmu.name, admin_fmu_path(fmu.id)) if fmu
    end

    column :user, sortable: 'users.name'
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    attachment_column :attachment
    column('Approve') { |annex| link_to 'Approve', approve_admin_operator_document_annex_path(annex), method: :put }
    column('Reject') { |annex| link_to 'Reject', reject_admin_operator_document_annex_path(annex), method: :put }
    actions
  end


  filter :annex_documents_documentable_of_OperatorDocument_type_required_operator_document_name_equals,
          as: :select,
          label: 'Operator Document',
          collection: RequiredOperatorDocument.order(:name).pluck(:name)

  filter :annex_documents_documentable_of_OperatorDocument_type_operator_translations_name_equals,
          as: :select,
          label: 'Operator',
          collection: Operator.with_translations(I18n.locale)
                          .order('operator_translations.name').pluck(:name)
  filter :annex_documents_documentable_of_OperatorDocument_type_fmu_translations_name_equals,
         as: :select,
         label: 'FMU',
         collection: Fmu.with_translations(I18n.locale).order(:name).pluck(:name)
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

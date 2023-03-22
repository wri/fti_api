# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentAnnex do
  extend BackRedirectable
  extend Versionable

  menu false
  config.order_clause

  active_admin_paranoia

  # To include the deleted operator document annexes
  scope_to do
    Class.new do
      def self.operator_document_annexes
        OperatorDocumentAnnex.unscoped.distinct
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:user, annex_documents: [documentable: [:operator, required_operator_document: :translations]]])
    end
  end

  member_action :approve, method: :put do
    if resource.update(status: OperatorDocumentAnnex.statuses[:doc_valid])
      redirect_to collection_path, notice: I18n.t('active_admin.operator_document_annexes_page.approved')
    else
      redirect_to collection_path, alert: I18n.t('active_admin.operator_document_annexes_page.not_approved')
    end
  end

  member_action :reject, method: :put do
    if resource.update(status: OperatorDocumentAnnex.statuses[:doc_invalid])
      redirect_to collection_path, notice: I18n.t('active_admin.operator_document_annexes_page.rejected')
    else
      redirect_to collection_path, alert: I18n.t('active_admin.operator_document_annexes_page.not_rejected')
    end
  end

  actions :all, except: [:destroy, :new]
  permit_params :name, :status, :expire_date, :start_date,
                :attachment, :uploaded_by

  csv do
    column I18n.t('active_admin.required_operator_document_page.exists') do |annex|
      annex.deleted_at.nil?
    end
    column :status

    column I18n.t('active_admin.operator_page.documents') do |annex|
      documents = []
      annex.annex_documents.each do |ad|
        documents << ad.documentable
      end
      documents.split(' ')
    end
    column I18n.t('active_admin.dashboard_page.columns.operator') do |annex|
      annex.annex_documents.first&.documentable&.operator&.name
    end

    column I18n.t('activerecord.models.user') do |annex|
      annex.user&.name
    end
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
  end

  index do
    render partial: 'dependant_filters', locals: {
      filter: {
        annex_documents_documentable_of_OperatorDocument_type_operator_name_equals: {
          annex_documents_documentable_of_OperatorDocument_type_fmu_translations_name_equals:
            HashHelper.aggregate(
              Operator.joins(fmus: :translations).where(fmu_translations: { locale: I18n.locale }).pluck(:name, 'fmu_translations.name')
            )
        }
      }
    }

    bool_column I18n.t('active_admin.required_operator_document_page.exists') do |od|
      od.deleted_at.nil?
    end
    tag_column :status
    column I18n.t('active_admin.operator_page.documents') do |od|
      next if od.annex_document.nil?

      doc = OperatorDocument.unscoped.find(od.annex_document.documentable_id)
      link_to(doc.required_operator_document.name, admin_operator_document_path(doc.id))
    end
    column I18n.t('activerecord.models.operator_document_history') do |od|
      od.annex_documents_history.each_with_object([]) do |ad, links|
        doc = OperatorDocumentHistory.unscoped.find(ad.documentable_id)
        links << link_to(doc.required_operator_document.name, admin_operator_document_history_path(doc.id))
      end.reduce(:+)
    end
    column I18n.t('active_admin.dashboard_page.columns.operator') do |od|
      begin
        o = od.annex_documents_history.first.documentable.operator
        link_to(o.name, admin_producer_path(o.id))
      rescue StandardError
      end
    end
    column I18n.t('activerecord.models.fmu.one') do |od|
      doc = od.annex_documents.first
      next if doc.nil?

      fmu = doc.documentable_type.constantize.unscoped.find(doc.documentable_id).fmu
      link_to(fmu.name, admin_fmu_path(fmu.id)) if fmu
    end

    column :user, sortable: 'users.name'
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    column :attachment do |o|
      link_to o.attachment&.identifier, o.attachment&.url
    end
    column(I18n.t('active_admin.approve')) { |annex| link_to I18n.t('active_admin.approve'), approve_admin_operator_document_annex_path(annex), method: :put }
    column(I18n.t('active_admin.reject')) { |annex| link_to I18n.t('active_admin.reject'), reject_admin_operator_document_annex_path(annex), method: :put }
    actions
  end


  filter :annex_documents_documentable_of_OperatorDocument_type_required_operator_document_name_equals,
         as: :select,
         label: I18n.t('active_admin.operator_document_annexes_page.operator_document'),
         collection: -> { RequiredOperatorDocument.order(:name).pluck(:name) }

  filter :annex_documents_documentable_of_OperatorDocument_type_operator_name_equals,
         as: :select,
         label: I18n.t('activerecord.models.operator'),
         collection: -> { Operator.order(:name).pluck(:name) }
  filter :annex_documents_documentable_of_OperatorDocument_type_fmu_translations_name_equals,
         as: :select,
         label: I18n.t('activerecord.models.fmu.one'),
         collection: -> { Fmu.by_name_asc.pluck(:name) }

  filter :operator
  filter :status, as: :select, collection: OperatorDocumentAnnex.statuses
  filter :updated_at

  scope I18n.t('active_admin.operator_documents_page.pending'), :doc_pending
  scope I18n.t('active_admin.operator_document_annexes_page.orphaned'), :orphaned

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.operator_document_annexes_page.details') do
      f.input :operator_document_name, label: I18n.t('active_admin.operator_document_annexes_page.operator_document'),
                                       input_html: { disabled: true }
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
        row :attachment do |o|
          link_to o.attachment&.identifier, o.attachment&.url
        end
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

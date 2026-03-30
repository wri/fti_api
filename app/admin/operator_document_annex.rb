# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentAnnex do
  extend BackRedirectable
  extend Versionable

  menu false
  config.order_clause

  active_admin_paranoia

  controller do
    def scoped_collection
      end_of_association_chain.includes([:user, annex_documents: [documentable: [:operator, required_operator_document: :translations]]])
    end

    def apply_filtering(chain)
      super.distinct
    end
  end

  member_action :approve, method: :put do
    if resource.update(status: "doc_valid")
      redirect_back_or_to resource_path(resource), notice: I18n.t("active_admin.operator_document_annexes_page.approved")
    else
      redirect_back_or_to resource_path(resource), alert: I18n.t("active_admin.operator_document_annexes_page.not_approved")
    end
  end

  member_action :reject, method: [:get, :put] do
    @dialog_id = "reject-annex-dialog"
    if request.put?
      @success = resource.update(status: "doc_invalid", invalidation_reason: params.dig(:operator_document_annex, :invalidation_reason))
      flash[:notice] = I18n.t("active_admin.operator_documents_page.rejected") if @success
    end
  end

  action_item :reject, only: :show, if: proc { resource.rejectable? && params[:version].blank? } do
    link_to I18n.t("active_admin.reject"), reject_admin_operator_document_annex_path(resource, open_existing: true), remote: true
  end

  action_item :approve, only: :show, if: proc { resource.approvable? && params[:version].blank? } do
    approve_confirmation = I18n.t("active_admin.operator_documents_page.approve_confirmation", name: resource.name)
    link_to I18n.t("active_admin.approve"), approve_admin_operator_document_annex_path(resource), method: :put, data: {confirm: approve_confirmation}
  end

  actions :all, except: [:destroy, :new]
  permit_params :name, :status, :expire_date, :start_date, :attachment, :uploaded_by

  csv do
    column :status
    column I18n.t("active_admin.operator_page.documents") do |annex|
      documents = []
      annex.annex_documents.each do |ad|
        documents << ad.documentable
      end
      documents.split(" ")
    end
    column I18n.t("active_admin.dashboard_page.columns.operator") do |annex|
      annex.annex_documents.first&.documentable&.operator&.name
    end
    column I18n.t("activerecord.models.user") do |annex|
      annex.user&.name
    end
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
  end

  index do
    tag_column :status
    column I18n.t("active_admin.operator_page.documents") do |od|
      next if od.annex_document.nil?

      doc = OperatorDocument.unscoped.find(od.annex_document.documentable_id)
      link_to(doc.required_operator_document.name, admin_operator_document_path(doc.id))
    end
    column I18n.t("active_admin.dashboard_page.columns.operator") do |od|
      o = od.annex_documents_history.first.documentable.operator
      link_to(o.name, admin_producer_path(o.id))
    rescue
    end
    column I18n.t("activerecord.models.fmu.one") do |od|
      doc = od.annex_documents.first
      next if doc.nil?

      fmu = doc.documentable_type.constantize.unscoped.find(doc.documentable_id).fmu
      link_to(fmu.name, admin_fmu_path(fmu.id)) if fmu
    end
    column :user, sortable: "users.name"
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    column :attachment do |o|
      if o.attachment&.identifier.present?
        name = o.attachment.identifier
        name += " (Missing file)" if o.attachment.blank?
        link_to name, o.attachment.url
      end
    end
    if params[:scope] == "archived"
      column :deleted_at
    end
    actions defaults: false, name: I18n.t("active_admin.shared.actions") do |annex|
      if annex.approvable?
        approve_confirmation = I18n.t("active_admin.operator_documents_page.approve_confirmation", name: annex.name)
        item I18n.t("active_admin.approve"), approve_admin_operator_document_annex_path(annex), method: :put, data: {confirm: approve_confirmation}
      end
      item I18n.t("active_admin.reject"), reject_admin_operator_document_annex_path(annex), remote: true if annex.rejectable?
    end
    actions
  end

  filter :operator_document_required_operator_document_name_or_operator_document_histories_required_operator_document_name_eq,
    as: :select,
    label: proc { I18n.t("active_admin.operator_document_annexes_page.operator_document") },
    collection: -> { RequiredOperatorDocument.order(:name).pluck(:name).uniq }
  filter :operator_document_operator_name_or_operator_document_histories_operator_name_eq,
    as: :select,
    label: proc { I18n.t("activerecord.models.operator") },
    collection: -> { Operator.order(:name).pluck(:name) }
  filter :operator_document_fmu_name_or_operator_document_histories_fmu_name_eq,
    as: :select,
    label: -> { I18n.t("activerecord.models.fmu.one") },
    collection: -> { Fmu.by_name_asc.pluck(:name) }
  filter :status, as: :select, collection: OperatorDocumentAnnex.statuses.transform_keys(&:humanize)
  filter :updated_at

  dependent_filters do
    {
      operator_document_operator_name_or_operator_document_histories_operator_name_eq: {
        operator_document_fmu_name_or_operator_document_histories_fmu_name_eq:
          Operator.joins(:fmus).pluck(:name, "fmus.name")
      }
    }
  end

  scope -> { I18n.t("active_admin.operator_documents_page.pending") }, :doc_pending
  scope -> { I18n.t("active_admin.operator_document_annexes_page.orphaned") }, :orphaned
  scope -> { I18n.t("active_admin.operator_document_annexes_page.history_annexes") }, :history_annexes

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.operator_document_annexes_page.details") do
      f.input :operator_document_name, label: I18n.t("active_admin.operator_document_annexes_page.operator_document"),
        input_html: {disabled: true}
      f.input :uploaded_by
      f.input :name
      f.input :status, include_blank: false, input_html: {disabled: true}
      f.input :attachment, hint: preview_file_tag(f.object.attachment)
    end
  end

  show do
    attributes_table do
      row :name
      tag_row :status
      row :invalidation_reason if resource.invalidation_reason.present? || resource.doc_invalid?
      row :required_operator_document do
        resource.operator_document.required_operator_document if resource.operator_document.present? &&
          resource.operator_document.required_operator_document.present?
      end
      row :operator do
        resource.operator_document.presence&.operator
      end
      row :operator_document do |a|
        if a.annex_document.present?
          doc = OperatorDocument.unscoped.find(a.annex_document.documentable_id)
          link_to(doc.required_operator_document.name, admin_operator_document_path(doc.id))
        end
      end
      row :operator_document_history do |a|
        table_for a.operator_document_histories.order(operator_document_updated_at: :desc) do
          column :id do |history|
            link_to history.id, admin_operator_document_history_path(history)
          end
          tag_column :status
          column :operator_document_updated_at
          column :attachment do |history|
            if history.document_file&.attachment.present?
              link_to history.document_file.attachment.identifier, history.document_file.attachment.url, target: "_blank", rel: "noopener"
            elsif history.reason.present?
              history.reason
            end
          end
        end
      end
      row :uploaded_by
      row :user
      row :attachment do |o|
        if o.attachment&.identifier.present?
          name = o.attachment.identifier
          name += " (Missing file)" if o.attachment.blank?
          link_to name, o.attachment.url
        end
      end
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
  end
end

# frozen_string_literal: true

ActiveAdmin.register OperatorDocument do
  extend BackRedirectable
  extend Versionable

  menu false
  config.sort_order = "updated_at_desc"

  active_admin_paranoia

  controller do
    def scoped_collection
      end_of_association_chain
        .includes([:required_operator_document, :user, :operator, :fmu,
          [required_operator_document:
             [required_operator_document_group: :translations, country: :translations]]])
    end
  end

  # Here we're updating the documents one by one to make sure the callbacks to
  # create a new version and to change the last modified (and the author) are called
  batch_action :make_private, confirm: I18n.t("active_admin.operator_documents_page.confirm_private") do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(public: false)
    end
    redirect_to collection_path, notice: I18n.t("active_admin.operator_documents_page.private_confirmed")
  end

  batch_action :make_public, confirm: I18n.t("active_admin.operator_documents_page.confirm_public") do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(public: true)
    end
    redirect_to collection_path, notice: I18n.t("active_admin.operator_documents_page.public_confirmed")
  end

  batch_action :set_source_by_company,
    confirm: I18n.t("active_admin.operator_documents_page.confirm_company") do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(source: OperatorDocument.sources[:company])
    end
    redirect_to collection_path, notice: I18n.t("active_admin.operator_documents_page.company_confirmed")
  end

  batch_action :set_source_by_forest_atlas,
    confirm: I18n.t("active_admin.operator_documents_page.confirm_fa") do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(source: OperatorDocument.sources[:forest_atlas])
    end
    redirect_to collection_path, notice: I18n.t("active_admin.operator_documents_page.fa_confirmed")
  end

  batch_action :set_source_by_other,
    confirm: I18n.t("active_admin.operator_documents_page.confirm_other") do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(source: OperatorDocument.sources[:other_source])
    end
    redirect_to collection_path, notice: I18n.t("active_admin.operator_documents_page.other_confirmed")
  end

  action_item :approve, only: :show, if: proc { resource.doc_pending? && params[:version].blank? } do
    approve_confirmation = I18n.t("active_admin.operator_documents_page.approve_confirmation", name: resource.name_with_fmu)
    link_to I18n.t("active_admin.approve"), approve_admin_operator_document_path(resource), method: :put, data: {confirm: approve_confirmation}
  end

  action_item :reject, only: :show, if: proc { resource.doc_pending? && params[:version].blank? } do
    link_to I18n.t("active_admin.reject"), reject_admin_operator_document_path(resource, open_existing: true), remote: true
  end

  member_action :reject, method: [:get, :put] do
    unless resource.doc_pending?
      redirect_back_or_to resource_path(resource), notice: I18n.t("active_admin.operator_documents_page.not_pending") and return
    end
    resource.admin_comment = nil if request.get? # Clear comment when opening the dialog for the first time
    @dialog_id = "reject-document-dialog"
    if request.put?
      resource.status = "doc_invalid"
      resource.admin_comment = params.dig(:operator_document, :admin_comment)
      @success = resource.save
      flash[:notice] = I18n.t("active_admin.operator_documents_page.rejected") if @success
    end
  end

  member_action :approve, method: :put do
    unless resource.doc_pending?
      redirect_back_or_to resource_path(resource), notice: I18n.t("active_admin.operator_documents_page.not_pending") and return
    end

    resource.status = resource.reason.present? ? "doc_not_required" : "doc_valid"
    if resource.save
      redirect_back_or_to resource_path(resource), notice: I18n.t("active_admin.operator_documents_page.approved")
    else
      redirect_back_or_to resource_path(resource), alert: I18n.t("active_admin.operator_documents_page.error_approving")
    end
  end

  member_action :perform_qc, method: :get do
    redirect_to resource_path(resource)
  end

  actions :all, except: [:destroy, :new]
  permit_params :name, :public, :required_operator_document_id,
    :operator_id, :type, :status, :expire_date, :start_date,
    :uploaded_by, :admin_comment, :reason, :response_date,
    :source, :source_info, document_file_attributes: [:id, :attachment, :filename]

  csv do
    column :exists do |o|
      o.deleted_at.nil? && o.required_operator_document.deleted_at.nil?
    end
    column :public
    column :status
    column :admin_comment
    column :id
    column :required_operator_document do |o|
      o.required_operator_document.name
    end
    column :country do |o|
      o.required_operator_document&.country&.name
    end
    column :Type do |o|
      if o.required_operator_document.present?
        (o.required_operator_document.type == "RequiredOperatorDocumentFmu") ? "Fmu" : "Operator"
      else
        RequiredOperatorDocument.unscoped.find(o.required_operator_document_id).type
      end
    end
    column :operator do |o|
      o.operator.name
    end
    column :fmu do |o|
      o.fmu&.name
    end
    column I18n.t("active_admin.operator_documents_page.legal_category") do |o|
      if o.required_operator_document.present?
        o.required_operator_document.required_operator_document_group.name
      else
        RequiredOperatorDocument.unscoped.find(o.required_operator_document_id).required_operator_document_group.name
      end
    end
    column :user do |o|
      o.user&.name
    end
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    column :attachment do |o|
      o&.document_file&.attachment
    end
    column I18n.t("active_admin.operator_documents_page.annexes") do |o|
      links = []
      o.operator_document_annexes.each { |a| links << a.name }
      safe_join(links, " ")
    end
    column :reason
    column :response_date
  end

  index do
    selectable_column
    column :public
    tag_column :status, &:detailed_status
    column :id
    column I18n.t("activerecord.models.country.one") do |od|
      od.required_operator_document.country
    end
    column I18n.t("active_admin.operator_documents_page.required"), :required_operator_document, sortable: "required_operator_document_id" do |od|
      if od.required_operator_document.present?
        link_to od.required_operator_document.name, admin_required_operator_document_path(od.required_operator_document)
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).name
      end
    end
    column :Type, sortable: false do |od|
      if od.required_operator_document.present?
        (od.required_operator_document.type == "RequiredOperatorDocumentFmu") ? "Fmu" : "Operator"
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).type
      end
    end
    column :operator, sortable: "operator_id"
    column :fmu, sortable: "fmu_id" do |od|
      if od.fmu.present?
        link_to od.fmu.name, admin_fmu_path(od.fmu)
      elsif od.fmu_id.present?
        Fmu.unscoped.find(od.fmu_id).name
      end
    end
    column I18n.t("active_admin.operator_documents_page.legal_category") do |od|
      if od.required_operator_document.present?
        od.required_operator_document.required_operator_document_group.name
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).required_operator_document_group.name
      end
    end
    column :user, sortable: "user_id"
    column :expire_date
    column :start_date
    column :deleted_at
    column :created_at
    column :uploaded_by
    column :source
    column I18n.t("active_admin.operator_documents_page.attachment") do |od|
      if od&.document_file&.attachment
        link_to od.document_file.attachment.identifier, od.document_file.attachment.url
      elsif od.reason.present?
        I18n.t("active_admin.operator_documents_page.non_applicable")
      end
    end
    column I18n.t("active_admin.operator_documents_page.annexes") do |od|
      links = []
      od.operator_document_annexes.each { |a| links << link_to(a.id, admin_operator_document_annex_path(a)) }
      safe_join(links, " ")
    end
    column :admin_comment
    column :reason
    column :response_date
    unless params[:scope] == "archived"
      actions defaults: false, name: I18n.t("active_admin.shared.actions") do |document|
        if document.doc_pending?
          approve_confirmation = I18n.t("active_admin.operator_documents_page.approve_confirmation", name: document.name_with_fmu)
          item I18n.t("active_admin.approve"), approve_admin_operator_document_path(document), method: :put, data: {confirm: approve_confirmation}
          item I18n.t("active_admin.reject"), reject_admin_operator_document_path(document), remote: true
        end
      end
    end
    actions
  end

  filter :public
  filter :id
  filter :required_operator_document_country_id,
    label: proc { I18n.t("activerecord.models.country.one") },
    as: :select,
    collection: -> { Country.joins(:required_operator_documents).by_name_asc.distinct }
  filter :required_operator_document,
    collection: -> { RequiredOperatorDocument.with_generic.order(:country_id, :name).map { |r| [r.name_with_country, r.id] } }
  filter :operator, as: :select, collection: -> { Operator.by_name_asc }
  filter :fmu, as: :select, label: -> { I18n.t("activerecord.models.fmu.other") }, collection: -> { Fmu.by_name_asc }
  filter :status, as: :select, collection: -> { OperatorDocument.statuses.transform_keys(&:humanize) }
  filter :type, as: :select
  filter :source, as: :select, collection: -> { OperatorDocument.sources.transform_keys(&:humanize) }
  filter :updated_at

  dependent_filters do
    {
      required_operator_document_country_id: {
        required_operator_document_id: RequiredOperatorDocument.pluck(:country_id, :id),
        operator_id: Operator.pluck(:country_id, :id)
      },
      operator_id: {
        fmu_id: FmuOperator.where(current: true).distinct.pluck(:operator_id, :fmu_id)
      }
    }
  end

  scope -> { I18n.t("active_admin.operator_documents_page.pending") }, :doc_pending

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.operator_documents_page.details") do
      f.input :required_operator_document, input_html: {disabled: true}
      f.input :operator, input_html: {disabled: true}
      f.input :type, input_html: {disabled: true}
      f.input :uploaded_by, default: OperatorDocument.uploaded_bies[:admin]
      f.input :source
      f.input :source_info
      f.input :status, include_blank: false
      f.input :admin_comment
      f.input :public
      f.inputs for: [:document_file_attributes, f.object.document_file || DocumentFile.new] do |df|
        df.input :attachment, hint: preview_file_tag(df.object.attachment)
      end
      f.input :reason
      f.input :response_date, as: :date_picker
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker
    end
    f.actions
  end

  show title: proc { "#{resource.operator.name} - #{resource.required_operator_document.name}" } do
    attributes_table do
      row :public
      tag_row :status, &:detailed_status
      row(I18n.t("active_admin.operator_documents_page.reason_label"), &:reason) if resource.reason.present?
      row :admin_comment if resource.admin_comment.present?
      row :required_operator_document
      row :operator
      row :fmu, unless: resource.is_a?(OperatorDocumentCountry)
      row :uploaded_by
      row I18n.t("active_admin.operator_documents_page.attachment") do |r|
        if r.document_file&.attachment&.present?
          link_to r.document_file&.attachment&.identifier, r.document_file&.attachment&.url, target: "_blank", rel: "noopener"
        elsif r.reason.present?
          I18n.t("active_admin.operator_documents_page.non_applicable")
        end
      end
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end

    render partial: "annexes_table", locals: {resource: resource}

    panel I18n.t("activerecord.models.operator_document_history") do
      table_for OperatorDocumentHistory.where(operator_document_id: resource.id).order(operator_document_updated_at: :desc) do
        column :id do |history|
          link_to history.id, admin_operator_document_history_path(history)
        end
        tag_column :status
        column :operator_document_updated_at
        column :attachment do |history|
          if history.document_file&.attachment.present?
            link_to history.document_file.attachment.identifier, history.document_file.attachment.url, target: "_blank", rel: "noopener"
          end
        end
        column :annexes do |history|
          links = []
          history.operator_document_annexes.each do |annex|
            links << link_to(annex.id, admin_operator_document_annex_path(annex.id))
          end
          safe_join(links, ", ")
        end
      end
    end
  end
end

# frozen_string_literal: true

ActiveAdmin.register OperatorDocument do
  extend BackRedirectable
  extend Versionable

  menu false
  config.sort_order = "updated_at_desc"

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
      end_of_association_chain
        .includes([:required_operator_document, :user, :operator, :fmu,
          [required_operator_document:
             [required_operator_document_group: :translations, country: :translations]]])
    end

    def perform_qc_params
      params.require(:operator_document_qc_form).permit(:decision, :admin_comment) if params.key?(:operator_document_qc_form)
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

  action_item :start_qc, only: :show, if: proc { resource.doc_pending? } do
    link_to I18n.t("active_admin.shared.start_qc"), perform_qc_admin_operator_document_path(resource)
  end

  member_action :perform_qc, method: [:put, :get] do
    @page_title = I18n.t("active_admin.shared.perform_qc")
    @form = OperatorDocumentQCForm.new(resource, perform_qc_params)
    if request.put? && @form.call
      notice = if resource.doc_invalid?
        I18n.t("active_admin.operator_documents_page.rejected")
      else
        I18n.t("active_admin.operator_documents_page.approved")
      end
      redirect_to collection_path, notice: notice
    else
      render "perform_qc"
    end
  end

  member_action :approve, method: :put do
    form = OperatorDocumentQCForm.new(resource, decision: "doc_valid")
    if form.call
      redirect_to collection_path, notice: I18n.t("active_admin.operator_documents_page.approved")
    else
      redirect_to collection_path, alert: I18n.t("active_admin.operator_documents_page.error_approving")
    end
  end

  sidebar I18n.t("active_admin.operator_documents_page.annexes"), only: :show do
    attributes_table_for resource do
      ul do
        resource.operator_document_annexes.collect do |annex|
          li link_to(annex.name, admin_operator_document_annex_path(annex.id))
        end
      end
    end
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
    bool_column I18n.t("active_admin.required_operator_document_page.exists") do |od|
      od.deleted_at.nil? && od.required_operator_document.deleted_at.nil?
    end
    column :public
    tag_column :status
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
    column(I18n.t("active_admin.shared.actions")) do |document|
      a I18n.t("active_admin.shared.start_qc"), href: perform_qc_admin_operator_document_path(document) if document.doc_pending?
      a I18n.t("active_admin.approve"), href: approve_admin_operator_document_path(document), "data-method": :put if document.doc_pending?
      a I18n.t("active_admin.reject"), href: perform_qc_admin_operator_document_path(document) if document.doc_pending?
    end
    actions
  end

  filter :public
  filter :id
  filter :required_operator_document_country_id,
    label: proc { I18n.t("activerecord.models.country.one") },
    as: :select,
    collection: -> { Country.by_name_asc.where(id: RequiredOperatorDocument.select(:country_id).distinct.select(:country_id)) }
  filter :required_operator_document,
    collection: -> { RequiredOperatorDocument.with_generic.order(:country_id, :name).map { |r| [r.name_with_country, r.id] } }
  filter :operator, as: :select, collection: -> { Operator.by_name_asc }
  filter :fmu, as: :select, label: -> { I18n.t("activerecord.models.fmu.other") }, collection: -> { Fmu.by_name_asc }
  filter :status, as: :select, collection: -> { OperatorDocument.statuses }
  filter :type, as: :select
  filter :source, as: :select, collection: -> { OperatorDocument.sources }
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
        df.input :attachment
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
      tag_row :status
      row(I18n.t("active_admin.operator_documents_page.reason_label"), &:reason) if resource.reason.present?
      row :admin_comment if resource.admin_comment.present?
      row :required_operator_document
      row :operator
      row :fmu, unless: resource.is_a?(OperatorDocumentCountry)
      row :uploaded_by
      row I18n.t("active_admin.operator_documents_page.attachment") do |r|
        link_to r.document_file&.attachment&.identifier, r.document_file&.attachment&.url, target: "_blank", rel: "noopener" if r.document_file&.attachment&.present?
      end
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
  end
end

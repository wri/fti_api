# frozen_string_literal: true

ActiveAdmin.register ObservationDocument, as: "Evidence" do
  extend BackRedirectable
  extend Versionable

  menu false

  actions :all, except: [:new]

  config.order_clause
  active_admin_paranoia

  permit_params :name, :attachment

  member_action :really_destroy, method: :delete do
    if resource.deleted?
      resource.really_destroy!
      redirect_back fallback_location: admin_evidences_path, notice: I18n.t("active_admin.evidence_page.evidence_removed")
    else
      redirect_back fallback_location: admin_evidences_path, notice: I18n.t("active_admin.evidence_page.evidence_must_be_recycled")
    end
  end

  csv do
    column :id
    column :name
    column :user do |od|
      od.user&.name
    end
    column :created_at
    column :updated_at
    column :deleted_at
  end

  index do
    column :id
    column :observations
    column :name
    column :attachment do |o|
      link_to o&.name, o.attachment&.url if o.attachment&.url
    end
    column :user, sortable: "users.name"
    column :created_at
    column :updated_at
    column :deleted_at

    actions defaults: false do |evidence|
      if evidence.deleted?
        item I18n.t("active_admin.shared.restore"), restore_admin_evidence_path(evidence), method: :put
        item I18n.t("active_admin.shared.remove_completely"), really_destroy_admin_evidence_path(evidence),
          method: :delete, data: {confirm: I18n.t("active_admin.shared.sure_want_to_remove")}
      else
        item I18n.t("active_admin.shared.view"), admin_evidence_path(evidence)
        item I18n.t("active_admin.shared.edit"), edit_admin_evidence_path(evidence)
        item I18n.t("active_admin.shared.delete"), admin_evidence_path(evidence),
          method: :delete, data: {confirm: I18n.t("active_admin.shared.sure_want_to_recycle")}
      end
    end
  end

  filter :observations, as: :select, collection: -> { Observation.joins(:observation_documents).distinct.order(:id).pluck(:id) }
  filter :name, as: :select
  filter :attachment, as: :select
  filter :user
  filter :created_at
  filter :updated_at
  filter :deleted_at

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :observations, input_html: {disabled: true}
      f.input :user, input_html: {disabled: true}
      f.input :name
      f.input :attachment, as: :file, hint: f.object&.attachment&.file&.filename

      f.actions
    end
  end

  show do
    attributes_table do
      row :id
      row :observations
      row :attachment do |o|
        link_to o&.name, o.attachment&.url if o.attachment&.url
      end
      row :user
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, :observations)
    end
  end
end

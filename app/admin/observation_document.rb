# frozen_string_literal: true

ActiveAdmin.register ObservationDocument, as: 'Evidence' do
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
      redirect_back fallback_location: admin_evidences_path, notice: 'Evidence removed!'
    else
      redirect_back fallback_location: admin_evidences_path, notice: 'Evidence must be moved to recycle bin first!'
    end
  end

  csv do
    column :id
    column :observation do |od|
      od.observation&.id
    end
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
    column :observation, sortable: 'observation_id'
    column :name
    column :attachment do |o|
      link_to o&.name, o.attachment&.url if o.attachment&.url
    end
    column :user, sortable: 'users.name'
    column :created_at
    column :updated_at
    column :deleted_at

    actions defaults: false do |evidence|
      if evidence.deleted?
        item 'Restore', restore_admin_evidence_path(evidence), method: :put
        item 'Remove Completely', really_destroy_admin_evidence_path(evidence),
             method: :delete, data: { confirm: 'Are you sure you want to remove the evidence completely? This action is not reversible.' }
      else
        item 'View', admin_evidence_path(evidence)
        item 'Edit', edit_admin_evidence_path(evidence)
        item 'Delete', admin_evidence_path(evidence),
             method: :delete, data: { confirm: 'Are you sure you want to move evidence to the recycle bin?' }
      end
    end
  end

  filter :observation, as: :select, collection: -> { Observation.joins(:observation_documents).distinct.order(:id).pluck(:id) }
  filter :name, as: :select
  filter :attachment, as: :select
  filter :user
  filter :created_at
  filter :updated_at
  filter :deleted_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Evidence Details' do
      f.input :observation, collection: Observation.all.map { |o| [o.id, o.id] }, input_html: { disabled: true }
      f.input :user, input_html: { disabled: true }
      f.input :name
      f.input :attachment, as: :file, hint: f.object&.attachment&.file&.filename

      f.actions
    end
  end

  show do
    attributes_table do
      row :id
      row :observation
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
      end_of_association_chain.includes(:user)
    end
  end
end

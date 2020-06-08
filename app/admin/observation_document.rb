# frozen_string_literal: true

ActiveAdmin.register ObservationDocument, as: 'Evidence' do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  menu false

  actions :show, :index, :create

  config.order_clause

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
    column :id, sortable: true
    column :observation, sortable: true
    column :name, sortable: true
    attachment_column :attachment
    column :user, sortable: true
    column :created_at, sortable: true
    column :updated_at, sortable: :true
    column :deleted_at, sortable: true
    actions
  end

  filter :observation, as: :select,
                       collection: Observation.joins(:observation_documents)
                         .distinct.order(:id).pluck(:id)
  filter :name, as: :select
  filter :attachment, as: :select
  filter :user
  filter :created_at
  filter :updated_at
  filter :deleted_at


  show do
    attributes_table do
      row :id
      row :observation
      attachment_row :attachment
      row :user
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end
end

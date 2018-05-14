# frozen_string_literal: true

ActiveAdmin.register ObservationDocument, as: 'Evidence' do
  menu false

  actions :show, :index

  config.order_clause

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

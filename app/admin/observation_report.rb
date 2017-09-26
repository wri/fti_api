ActiveAdmin.register ObservationReport do
  menu parent: 'Uploaded Documents', priority: 1

  actions :show, :index

  config.order_clause
  active_admin_paranoia

  filter :id, as: :select
  filter :title, as: :select
  filter :attachment, as: :select
  filter :user, as: :select
  filter :publication_date
  filter :created_at

  index do
    column :id
    column :title
    column :publication_date
    attachment_column :attachment
    column :user
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row :title
      row :publication_date
      row :user
      row :created_at
      row :updated_at
      row :deleted_at
      attachment_row('File', :attachment, label: 'Download File')
    end
    active_admin_comments
  end
end
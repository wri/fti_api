ActiveAdmin.register ObservationReport do
  menu parent: 'Uploaded Documents', priority: 1

  actions :show, :index

  config.order_clause
  active_admin_paranoia

  index do
    column :id
    column :title
    column :publication_date
    attachment_column :attachment
    column :user
    column :created_at
    column :updated_at
  end
end
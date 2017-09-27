ActiveAdmin.register ObservationDocument, as: 'Evidence' do
  menu parent: 'Uploaded Documents', as: 'Evidence', priority: 2

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
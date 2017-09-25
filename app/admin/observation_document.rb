ActiveAdmin.register ObservationDocument do
  menu parent: 'Uploaded Documents', priority: 2

  actions :show, :index

  config.order_clause

  filter :name, as: :select
  filter :user, as: :select
  filter :created_at


  index do
    column :name
    column :observation do |o|
      link_to "#{o.observation.operator.name} - #{o.observation.publication_date}", admin_observation_path(o)
    end
    attachment_column :attachment
    column :user
    column :created_at
  end
end
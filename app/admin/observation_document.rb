ActiveAdmin.register ObservationDocument do
  menu parent: 'Uploaded Documents', priority: 2

  actions :show, :index

  config.order_clause
end
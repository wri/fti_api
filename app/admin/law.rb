ActiveAdmin.register Law do
  menu parent: 'Settings', priority: 3

  actions :new, :create, :show, :edit, :index

  config.order_clause

  permit_params :id, :subcategory_id, :infraction, :sanctions, :min_fine, :max_fine, :penal_servitude,
                :other_penalties, :flegt
end
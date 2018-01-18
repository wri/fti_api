# frozen_string_literal: true

ActiveAdmin.register Contact do
  # menu parent: 'User Management', priority: 3
  menu false
  permit_params :email, :name

  filter :name, as: :select
  filter :email, as: :select
  filter :created_at

  index do
    selectable_column
    column :name
    column :email
    column :created_at

    actions
  end

end

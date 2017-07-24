# frozen_string_literal: true
ActiveAdmin.register Operator do

  actions :all
  permit_params :name

  index do
#    column :name
#    column :details
    column :concession

    actions
  end

#  filter :name
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Country Details' do
#      f.input :name
#      f.input :details
    end
    f.actions
  end
end

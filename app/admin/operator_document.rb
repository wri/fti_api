ActiveAdmin.register OperatorDocument do
  menu parent: 'Documents', priority: 2

  actions :all, except: [:destroy, :new, :create]
  permit_params :name

  index do
    column :required_operator_document
    column :operator
    column :type
    column :expire_date
    column :start_date
    column :status

    actions
  end

  filter :required_operator_document
  filter :operator
  filter :type
  filter :status
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Details' do
      f.input :required_operator_document
      f.input :operator
      f.input :type
      f.input :status
      f.input :expire_date
      f.input :start_date

    end
    f.actions
  end
end
ActiveAdmin.register RequiredOperatorDocument do
  menu parent: 'Documents', priority: 1

  actions :all
  permit_params :name

  index do
    column :required_operator_document_group
    column :country
    column :type
    column :name

    actions
  end

  filter :required_operator_document_group
  filter :country
  filter :type
  filter :name
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Document Details' do
      disable = object.new_record? ? false : true
      f.input :required_operator_document_group, input_html: { disabled: disable }
      f.input :country, input_html: { disabled: disable }
      f.input :type, input_html: { disabled: disable }
      f.input :name
    end
    f.actions
  end
end
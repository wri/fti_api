ActiveAdmin.register RequiredOperatorDocument do
  menu parent: 'Documents', priority: 1

  actions :all
  permit_params :name, :type, :valid_period, :country, :required_operator_document_group_id, :country_id

  index do
    column :required_operator_document_group
    column :country
    column :type
    column :name

    actions
  end

  filter :required_operator_document_group
  filter :country
  filter :type, as: :select, collection: %w(RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu)
  filter :name, as: :select
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Document Details' do
      editing = object.new_record? ? false : true
      f.input :required_operator_document_group
      f.input :country
      f.input :type, as: :select, collection: %w(RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu),
              include_blank: false, input_html: { disabled: editing }
      f.input :name
      f.input :valid_period, label: 'Validity (days)'
    end
    f.actions
  end

  controller do
    def create
      super do |format|
        redirect_to collection_url and return if resource.valid?
      end
    end

    def update
      super do |format|
        redirect_to collection_url and return if resource.valid?
      end
    end
  end
end
# frozen_string_literal: true

ActiveAdmin.register RequiredOperatorDocument do
  extend BackRedirectable
  back_redirect

  menu false

  active_admin_paranoia

  actions :all
  permit_params :name, :type, :forest_type, :valid_period, :contract_signature,
                :country, :required_operator_document_group_id, :country_id,
                translations_attributes: [:id, :locale, :explanation]

  csv do
    column 'exists' do |rod|
      rod.deleted_at.nil?
    end
    column 'required_operator_document_group' do |rod|
      rod.required_operator_document_group&.name
    end
    column 'country' do |rod|
      rod.country&.name
    end
    column :type
    column :name

  end

  index do
    bool_column :exists do |rod|
      rod.deleted_at.nil?
    end
    column :contract_signature
    column :required_operator_document_group
    column :country
    column :type
    column :name

    actions
  end

  filter :contract_signature, as: :select, collection: [['True', true], ['False', false]]
  filter :required_operator_document_group
  filter :country
  filter :type, as: :select, collection: %w(RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu)
  filter :forest_type, as: :select
  filter :name, as: :select
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Document Details' do
      editing = object.new_record? ? false : true
      f.input :required_operator_document_group
      f.input :contract_signature, input_html: { disabled: editing }
      f.input :country, input_html: { disabled: editing }
      f.input :type, as: :select, collection: %w(RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu),
                     include_blank: false, input_html: { disabled: editing }
      f.input :forest_type, as: :select,
                            collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.first] },
                            include_blank: true, input_html: { disabled: editing }
      f.input :name
      f.input :valid_period, label: 'Validity (days)'
      f.inputs 'Translated fields' do
        f.translated_inputs switch_locale: false do |t|
          t.input :explanation
        end
      end
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

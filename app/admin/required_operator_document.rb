# frozen_string_literal: true

ActiveAdmin.register RequiredOperatorDocument do
  extend BackRedirectable
  extend Versionable
  versionate

  menu false

  active_admin_paranoia

  actions :all
  permit_params :name, :type, :valid_period, :contract_signature, :country, :position,
                :required_operator_document_group_id, :country_id, forest_types: [],
                                                                   translations_attributes: [:id, :locale, :explanation]

  csv do
    column 'exists' do |rod|
      rod.deleted_at.nil?
    end
    column 'publication_authorization' do |rod|
      rod.contract_signature
    end
    column 'required_operator_document_group' do |rod|
      rod.required_operator_document_group&.name
    end
    column 'country' do |rod|
      rod.country&.name
    end
    column :type
    column :name
    column :forest_types do |rod|
      rod.forest_types.presence || ''
    end
  end

  index do
    bool_column :exists do |rod|
      rod.deleted_at.nil?
    end
    column 'Publication Authorization', :contract_signature
    column :required_operator_document_group
    column :country, sortable: 'country_translations.name'
    column :position
    column :type
    column :forest_types do |rod|
      rod.forest_types.presence || ''
    end
    column :name

    actions
  end

  filter :contract_signature, label: 'publication authorization', as: :select, collection: [['True', true], ['False', false]]
  filter :required_operator_document_group
  filter :country
  filter :type, as: :select, collection: %w(RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu)
  filter 'forest_types_contains_array', as: :select, collection: RequiredOperatorDocument::FOREST_TYPES.map{ |k,h| [k, h[:index]] }
  filter :name, as: :select
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Document Details' do
      editing = object.new_record? ? false : true
      f.input :required_operator_document_group
      f.input :contract_signature, label: 'Publication Authorization', input_html: { disabled: editing }
      f.input :country, input_html: { disabled: editing }
      f.input :position
      f.input :type, as: :select, collection: %w(RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu),
                     include_blank: false, input_html: { disabled: editing }
      if editing
        f.input :forest_types, as: :string, input_html: { disabled: editing }
      else
        f.input :forest_types, as: :select, multiple: true,
                               collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.last[:index]] },
                               include_blank: true
      end

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
    def scoped_collection
      end_of_association_chain.includes(country: :translations)
    end

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

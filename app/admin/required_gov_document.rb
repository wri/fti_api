# frozen_string_literal: true

ActiveAdmin.register RequiredGovDocument do
  extend BackRedirectable
  extend Versionable

  menu false

  active_admin_paranoia

  actions :all
  permit_params :required_gov_document_group_id, :document_type, :country_id, :position,
                :name, :valid_period, translations_attributes: [:id, :locale, :explanation]

  filter :required_gov_document_group, collection: -> {
    RequiredGovDocumentGroup
      .all
      .left_joins(:parent)
      .order('coalesce(parents_required_gov_document_groups.position, required_gov_document_groups.position)')
  }
  filter :country
  filter :document_type, as: :select, collection: RequiredGovDocument.document_types
  filter :translations_name_eq,
         as: :select, label: 'Name',
         collection: -> {
           RequiredGovDocument.with_translations(I18n.locale).order('required_gov_document_translations.name').pluck(:name)
         }
  filter :updated_at

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
        .includes(country: :translations, required_gov_document_group: [:translations, parent: :translations])
    end
  end

  csv do
    column 'exists' do |rd|
      rd.deleted_at.nil?
    end
    column 'required_gov_document_group' do |rd|
      rd.required_gov_document_group&.name
    end
    column 'country' do |rd|
      rd.country&.name
    end
    column :name
  end

  index do
    bool_column :exists do |rod|
      rod.deleted_at.nil?
    end
    column :required_gov_document_group
    column :country
    column :position
    column :name, sortable: 'required_gov_document_translations.name'
    column :document_type

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Gov Document Details' do
      editing = object.new_record? ? false : true
      f.input :required_gov_document_group, collection: RequiredGovDocumentGroup
        .all
        .left_joins(:parent)
        .order('coalesce(parents_required_gov_document_groups.position, required_gov_document_groups.position)')
      f.input :country, input_html: { disabled: editing }
      f.input :position
      f.input :document_type, as: :select, collection: RequiredGovDocument.document_types.keys,
                              include_blank: false, input_html: { disabled: editing }
      f.input :valid_period, label: 'Validity (days)'
      f.inputs 'Translated fields' do
        f.translated_inputs switch_locale: false do |t|
          t.input :name
          t.input :explanation
        end
      end
    end
    f.actions
  end
end

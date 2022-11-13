# frozen_string_literal: true

ActiveAdmin.register RequiredGovDocument do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  menu false

  active_admin_paranoia

  actions :all
  permit_params :required_gov_document_group_id, :document_type, :country_id, :position,
                :name, :valid_period, translations_attributes: [:id, :locale, :explanation]

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
    column :name
    column :document_type

    actions
  end

  filter :required_gov_document_group
  filter :country
  filter :document_type, as: :select, collection: RequiredGovDocument.document_types
  filter :name, as: :select
  filter :updated_at


  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Gov Document Details' do
      editing = object.new_record? ? false : true
      f.input :required_gov_document_group
      f.input :country, input_html: { disabled: editing }
      f.input :position
      f.input :document_type, as: :select, collection: RequiredGovDocument.document_types.keys,
                              include_blank: false, input_html: { disabled: editing }
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
end

# frozen_string_literal: true

ActiveAdmin.register RequiredOperatorDocument do
  extend BackRedirectable
  extend Versionable

  menu false

  active_admin_paranoia

  actions :all
  permit_params :name, :type, :valid_period, :contract_signature, :country, :position,
    :required_operator_document_group_id, :country_id, forest_types: [],
    translations_attributes: [:id, :locale, :explanation]

  csv do
    column I18n.t("active_admin.required_operator_document_page.exists") do |rod|
      rod.deleted_at.nil?
    end
    column I18n.t("active_admin.required_operator_document_page.publication_authorization") do |rod|
      rod.contract_signature
    end
    column I18n.t("activerecord.models.required_operator_document_group") do |rod|
      rod.required_operator_document_group&.name
    end
    column I18n.t("activerecord.models.country.one") do |rod|
      rod.country&.name
    end
    column :type
    column :name
    column :forest_types do |rod|
      rod.forest_types.presence || ""
    end
  end

  index do
    bool_column :exists do |rod|
      rod.deleted_at.nil?
    end
    column I18n.t("active_admin.required_operator_document_page.publication_authorization"), :contract_signature
    column :required_operator_document_group
    column :country, sortable: "country_translations.name"
    column :position
    column :type
    column :forest_types do |rod|
      rod.forest_types.presence || ""
    end
    column :name

    actions
  end

  filter :contract_signature,
    label: proc { I18n.t("active_admin.required_operator_document_page.publication_authorization") },
    as: :select, collection: [[I18n.t("active_admin.true"), true], [I18n.t("active_admin.false"), false]]
  filter :required_operator_document_group
  filter :country, collection: -> { Country.by_name_asc.where(id: RequiredOperatorDocument.select(:country_id).distinct.select(:country_id)) }
  filter :type, as: :select, collection: %w[RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu]
  filter "forest_types_contains_array",
    as: :select,
    label: proc { Fmu.human_attribute_name(:forest_type) },
    collection: -> { ForestType.select_collection }
  filter :name, as: :select
  filter :updated_at

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.required_operator_document_page.details") do
      editing = !object.new_record?
      f.input :required_operator_document_group
      f.input :contract_signature,
        label: I18n.t("active_admin.required_operator_document_page.publication_authorization"),
        input_html: {disabled: editing}
      f.input :country, input_html: {disabled: editing}
      f.input :position
      f.input :type, as: :select, collection: %w[RequiredOperatorDocumentCountry RequiredOperatorDocumentFmu],
        include_blank: false, input_html: {disabled: editing}
      if editing
        f.input :forest_types, as: :string, input_html: {disabled: editing}
      else
        f.input :forest_types, as: :select, multiple: true,
          collection: ForestType.select_collection,
          include_blank: true
      end

      f.input :name
      f.input :valid_period, label: I18n.t("active_admin.required_operator_document_page.validity")
      f.inputs I18n.t("active_admin.shared.translated_fields") do
        f.translated_inputs "Translations", switch_locale: false do |t|
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

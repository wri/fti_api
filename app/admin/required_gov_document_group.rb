# frozen_string_literal: true

ActiveAdmin.register RequiredGovDocumentGroup do
  extend BackRedirectable

  menu false

  active_admin_paranoia

  actions :all
  permit_params :position, :parent_id, translations_attributes: [:id, :locale, :name, :description]

  sidebar :required_gov_documents, only: :show do
    sidebar = RequiredGovDocument.where(required_gov_document_group: resource).collect do |rd|
      auto_link(rd, rd.name.camelize)
    end
    safe_join(sidebar, content_tag("br"))
  end

  csv do
    column :position
    column :parent
    column :name
    column :description
  end

  index do
    translation_status
    column :parent
    column :position, sortable: true
    column :name, sortable: "required_gov_document_group_translations.name"

    actions
  end

  filter :translations_name_cont,
    as: :select,
    label: -> { I18n.t("activerecord.attributes.required_gov_document_group/translation.name") },
    collection: -> {
      RequiredGovDocumentGroup.with_translations(I18n.locale)
        .order("required_gov_document_group_translations.name").pluck(:name)
    }
  filter :parent, collection: -> { RequiredGovDocumentGroup.top_level }
  filter :updated_at

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Required Gov Document Group Details" do
      f.input :position
      f.input :parent, collection: RequiredGovDocumentGroup.top_level
      f.translated_inputs "Translations", switch_locale: false do |t|
        t.input :name
        t.input :description
      end
    end
    f.actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end
end

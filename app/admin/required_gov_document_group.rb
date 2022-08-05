# frozen_string_literal: true

ActiveAdmin.register RequiredGovDocumentGroup do
  extend BackRedirectable
  back_redirect

  menu false

  active_admin_paranoia

  actions :all
  permit_params :position, translations_attributes: [:id, :locale, :name, :description]

  sidebar :required_gov_documents, only: :show do
    sidebar = RequiredGovDocument.where(required_gov_document_group: resource).collect do |rd|
      auto_link(rd, rd.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end


  csv do
    column :position
    column :name
    column :description
  end

  index do
    translation_status
    column :position, sortable: true
    column :name, sortable: 'required_gov_document_group_translations.name'

    actions
  end

  filter :translations_name_contains,
         as: :select,
         collection: -> {
           RequiredGovDocumentGroup.with_translations(I18n.locale)
             .order('required_gov_document_group_translations.name').pluck(:name)
         }
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Gov Document Group Details' do
      f.input :position
      f.translated_inputs switch_locale: false do |t|
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

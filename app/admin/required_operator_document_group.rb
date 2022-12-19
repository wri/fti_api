# frozen_string_literal: true

ActiveAdmin.register RequiredOperatorDocumentGroup do
  extend BackRedirectable

  menu false

  actions :all, except: :destroy
  permit_params :position, translations_attributes: [:id, :locale, :name]

  sidebar :required_operator_documents, only: :show do
    sidebar = RequiredOperatorDocument.where(required_operator_document_group: resource).collect do |rod|
      auto_link(rod, rod.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  csv do
    column :position
    column :name
  end

  index do
    translation_status
    column :position, sortable: true
    column :name, sortable: 'required_operator_document_group_translations.name'

    actions
  end

  filter :translations_name_contains,
         as: :select,
         collection: -> {
           RequiredOperatorDocumentGroup.with_translations(I18n.locale)
             .order('required_operator_document_group_translations.name')
             .pluck(:name)
         }
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Document Group Details' do
      f.input :position
      f.translated_inputs switch_locale: false do |t|
        t.input :name
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

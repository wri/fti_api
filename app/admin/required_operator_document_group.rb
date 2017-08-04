ActiveAdmin.register RequiredOperatorDocumentGroup do
  menu parent: 'Documents', priority: 0

  actions :all, except: :destroy
  permit_params :name

  sidebar :required_operator_documents, only: :show do
    sidebar = RequiredOperatorDocument.where(required_operator_document_group: resource).collect do |rod|
      auto_link(rod, rod.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  index do
    translation_status
    column :name
    column :concession

    actions
  end

  filter :name
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Required Operator Document Group Details' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end
    f.actions
  end
end
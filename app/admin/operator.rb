# frozen_string_literal: true
ActiveAdmin.register Operator do

  actions :all, except: :destroy
  permit_params :name, :country_id, :details, :concession, :is_active, :certification,
                translations_attributes: [:id, :locale, :name, :details, :destroy]

  index do
    translation_status
    column :country
    column :name
    column :concession

    actions
  end

  #filter :name
  filter :country
  filter :concession
  filter :updated_at

  sidebar 'Documents', only: :show do
    attributes_table_for resource do
      ul do
        resource.operator_documents.collect do |od|
          li link_to("[#{od.status}] #{od.required_operator_document.name}", admin_operator_document_path(od.id))
        end
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
        t.input :details
      end
    end
    f.inputs 'Country Details' do
      f.input :country
      f.input :certification
      f.input :concession
      f.input :logo
      f.input :is_active
    end
    f.actions
  end
end

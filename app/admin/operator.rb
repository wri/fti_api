# frozen_string_literal: true
ActiveAdmin.register Operator do

  actions :all, except: :destroy
  permit_params :name, :operator_type, :country_id, :details, :concession, :is_active, :certification,
                translations_attributes: [:id, :locale, :name, :details, :destroy]

  index do
    translation_status
    column :country, sortable: true
    column :name
    column :concession, sortable: true
    column 'Score', :score_absolute, sortable: 'score_absolute' do |operator|
      "#{'%.2f' % operator.score_absolute}" rescue nil
    end
    column 'Obs/Visit', :obs_per_visit, sortable: true
    column '% Docs', :percentage_valid_documents_all, sortable: true

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
      f.input :operator_type
      f.input :country
      f.input :certification
      f.input :concession
      f.input :logo
      f.input :is_active
    end
    f.actions
  end
end

# frozen_string_literal: true

ActiveAdmin.register Government do
  menu parent: 'Settings', priority: 7

  config.order_clause

  actions :all, except: :destroy
  permit_params :country_id, translations_attributes: [:id, :locale, :government_entity, :details, :_destroy]

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [country: :translations]])
    end
  end


  index do
    column :country, sortable: 'country_translations.name'
    column :government_entity, sortable: 'government_translations.government_entity'
    column :details, sortable: 'government_translations.government_details'

    actions
  end

  filter :country
  filter :translations_government_entity_contains, as: :select, label: 'Entity',
                                                   collection: Government.joins(:translations).pluck(:government_entity)
  filter :translations_details_contains, as: :select, label: 'Details',
                                         collection: Government.joins(:translations).pluck(:details)

  sidebar 'Observations', only: :show do
    attributes_table_for resource do
      ul do
        resource.observations.collect do |obs|
          li link_to(obs.id, admin_observations_path(obs.id))
        end
      end
    end
  end

  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Government Details' do
      f.input :country, input_html: { disabled: edit }
    end

    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :government_entity
        t.input :details
      end
    end
    f.actions
  end

  show title: proc{ "#{resource.government_entity}" }do
    attributes_table do
      row :country
      row :government_entity
      row :details
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

# frozen_string_literal: true

ActiveAdmin.register Government do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  menu false

  config.order_clause

  actions :all
  permit_params :country_id, :is_active, translations_attributes: [:id, :locale, :government_entity, :details, :_destroy]

  controller do
    def scoped_collection
      end_of_association_chain.with_translations.includes(country: :translations)
        .where(country_translations: { locale: I18n.locale })
    end
  end

  scope :all
  scope :active, default: true

  csv do
    column :is_active
    column 'country' do |g|
      g.country&.name
    end
    column :government_entity
    column :details
  end

  index do
    column 'Active?', :is_active
    column :country, sortable: 'country_translations.name'
    column :government_entity, sortable: 'government_translations.government_entity'
    column :details, sortable: 'government_translations.details'

    actions
  end

  filter :country, as: :select,
                   collection: -> { Country.joins(:governments).with_translations(I18n.locale).order('country_translations.name') }
  filter :translations_government_entity_contains,
         as: :select, label: 'Entity',
         collection: -> {
           Government.with_translations(I18n.locale).order('government_translations.government_entity').pluck(:government_entity).uniq
         }
  filter :translations_details_contains,
         as: :select, label: 'Details',
         collection: -> {
           Government.with_translations(I18n.locale).order('government_translations.details').pluck(:details).uniq
         }

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
      f.input :is_active
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
      row :is_active
      row :country
      row :government_entity
      row :details
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

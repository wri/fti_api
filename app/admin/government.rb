# frozen_string_literal: true

ActiveAdmin.register Government do
  extend BackRedirectable
  extend Versionable

  menu false

  config.order_clause

  actions :all
  permit_params :country_id, :is_active, translations_attributes: [:id, :locale, :government_entity, :details, :_destroy]

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale).includes(country: :translations)
        .where(country_translations: { locale: I18n.locale })
    end
  end

  scope I18n.t('active_admin.all'), :all
  scope I18n.t('active_admin.shared.active'), :active, default: true

  csv do
    column :is_active
    column I18n.t('activerecord.models.country.one') do |g|
      g.country&.name
    end
    column :government_entity
    column :details
  end

  index do
    render partial: 'dependent_filters', locals: {
      filter: {
        country_id: {
          translations_government_entity_contains: HashHelper.aggregate(
            Government.by_entity_asc.distinct.pluck(:country_id, :government_entity)
          )
        }
      }
    }

    column :is_active
    column :country, sortable: 'country_translations.name'
    column :government_entity, sortable: 'government_translations.government_entity'
    column :details, sortable: 'government_translations.details'

    actions
  end

  filter :country, as: :select, collection: -> { Country.joins(:governments).by_name_asc }
  filter :translations_government_entity_contains,
         as: :select, label: I18n.t('activerecord.attributes.government/translation.government_entity'),
         collection: -> { Government.by_entity_asc.distinct.pluck(:government_entity) }

  sidebar I18n.t('activerecord.models.observation.other'), only: :show do
    attributes_table_for resource do
      ul do
        resource.observations.collect do |obs|
          li link_to(obs.id, admin_observation_path(obs.id))
        end
      end
    end
  end

  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.shared.government_details') do
      f.input :is_active
      f.input :country, input_html: { disabled: edit }
    end

    f.inputs I18n.t('active_admin.shared.translated_fields') do
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

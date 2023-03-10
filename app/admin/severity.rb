# frozen_string_literal: true

ActiveAdmin.register Severity do
  extend BackRedirectable

  menu false

  actions :show, :edit, :index, :update, :new, :create

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.with_translations.includes(subcategory: :translations)
    end
  end

  permit_params :subcategory_id, :level, translations_attributes: [:id, :locale, :details, :_destroy]


  filter :translations_details_contains,
         as: :select, label: I18n.t('activerecord.attributes.severity.details'),
         collection: -> { Severity.with_translations(I18n.locale).order('severity_translations.details').pluck(:details) }
  filter :subcategory, as: :select,
                       collection: -> { Subcategory.with_translations(I18n.locale).order('subcategory_translations.name') }
  filter :level, as: :select, collection: 0..3
  filter :created_at
  filter :updated_at

  sidebar :observations, only: :show do
    sidebar = Observation.where(law: resource).collect do |obs|
      auto_link(obs, obs.id)
    end
    safe_join(sidebar, content_tag('br'))
  end

  csv do
    column :details
    column I18n.t('activerecord.models.subcategory') do |s|
      s.subcategory&.name
    end
    column :level
    column :created_at
    column :updated_at
  end

  index do
    column :details, sortable: 'severity_translations.details'
    column :subcategory, sortable: 'subcategory_translations.name'
    column :level
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    editing = object.new_record? ? false : true
    f.inputs I18n.t('active_admin.shared.severity_details') do
      f.input :subcategory,  input_html: { disabled: editing }
      f.input :level, input_html: { disabled: editing }
    end

    f.inputs I18n.t('active_admin.shared.translated_fields') do
      f.translated_inputs switch_locale: false do |t|
        t.input :details
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :subcategory
      row :level
      row :details
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

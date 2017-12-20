# frozen_string_literal: true

ActiveAdmin.register Severity do
  menu parent: 'Settings', priority: 3

  actions :show, :edit, :index, :update, :new, :create

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [subcategory: :translations]])
    end
  end

  permit_params :subcategory_id, :level, translations_attributes: [:id, :locale, :details, :_destroy]


  filter :translations_details_contains, as: :select, label: 'Details',
                                         collection: Severity.joins(:translations).pluck(:details)
  filter :subcategory, as: :select
  filter :level, as: :select, collection: 0..3
  filter :created_at
  filter :updated_at

  sidebar :observations, only: :show do
    sidebar = Observation.where(law: resource).collect do |obs|
      auto_link(obs, obs.id)
    end
    safe_join(sidebar, content_tag('br'))
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
    f.semantic_errors *f.object.errors.keys
    editing = object.new_record? ? false : true
    f.inputs 'Severity Details' do
      f.input :subcategory,  input_html: { disabled: editing }
      f.input :level, input_html: { disabled: editing }
    end

    f.inputs 'Translated fields' do
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

# frozen_string_literal: true

ActiveAdmin.register Subcategory do
  # menu parent: 'Settings', priority: 2
  menu false

  actions :create, :show, :edit, :index, :update

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [category: :translations]])
    end
  end

  permit_params :location_required, translations_attributes: [:id, :locale, :name, :_destroy]

  scope :all, default: true
  scope :operator
  scope :government

  filter :translations_name_contains, as: :select, label: 'Name',
                                      collection: Subcategory.joins(:translations).pluck(:name)
  filter :category, as: :select
  filter :created_at
  filter :updated_at

  sidebar :laws, only: :show do
    sidebar = Law.where(subcategory: resource).collect do |law|
      auto_link(law, law.written_infraction&.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  sidebar :severities, only: :show do
    sidebar = Severity.where(subcategory: resource).collect do |sev|
      auto_link(sev, sev.level)
    end
    safe_join(sidebar, content_tag('br'))
  end

  index do
    column :name, sortable: 'subcategory_translations.name'
    column :category, sortable: 'category_translations.name'
    column :subcategory_type
    column :location_required
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Subcategory Details' do
      f.input :category,          input_html: { disabled: true }
      f.input :subcategory_type,  input_html: { disabled: true }
      f.input :location_required
    end

    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :category
      row :subcategory_type
      row :name
      row :location_required
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

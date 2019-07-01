# frozen_string_literal: true

ActiveAdmin.register Category do
  menu false

  actions :all, :except => [:destroy]

  config.order_clause
  config.filters = false

  scope :all, default: true
  scope :operator
  scope :government

  permit_params :category_type, translations_attributes: [:id, :locale, :name, :_destroy]

  sidebar :subcategories, only: :show do
    sidebar = Subcategory.joins(:translations).where(category: resource).collect do |s|
      auto_link(s, s.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations])
    end
  end

  csv do
    column :name
    column :category_type
    column :created_at
    column :updated_at
  end

  index do
    column :name
    column :category_type
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Category Details' do
      f.input :category_type, input_html: { disabled: edit }
    end
    f.translated_inputs switch_locale: false do |t|
      t.input :name
    end
    f.actions
  end
end

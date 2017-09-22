ActiveAdmin.register Subcategory do
  menu parent: 'Settings', priority: 2

  actions :create, :show, :edit, :index, :update

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [category: :translations]])
    end
  end

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
      auto_link(law, law.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  index do
    column :name, sortable: 'subcategory_translations.name'
    column :category, sortable: 'category_translations.name'
    column :subcategory_type
    column :created_at
    column :updated_at

    actions
  end
end
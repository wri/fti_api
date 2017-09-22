ActiveAdmin.register Category do
  menu parent: 'Settings', priority: 1

  actions :create, :show, :edit, :index

  config.order_clause
  config.filters = false

  scope :all, default: true
  scope :operator
  scope :government

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

  index do
    column :name
    column :category_type
    column :created_at
    column :updated_at

    actions
  end
end
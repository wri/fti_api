ActiveAdmin.register Subcategory do
  menu parent: 'Settings', priority: 2

  actions :create, :show, :edit, :index

  config.order_clause

  scope :all, default: true
  scope :operator
  scope :government

  sidebar :laws, only: :show do
    sidebar = Law.where(subcategory: resource).collect do |law|
      auto_link(law, law.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  index do
    column :name
    column :category
    column :category_type
    column :created_at
    column :updated_at

    actions
  end
end
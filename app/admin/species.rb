ActiveAdmin.register Species do
  menu parent: 'Settings', priority: 5

  actions :create, :show, :edit, :index

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations])
    end
  end
end
# frozen_string_literal: true

ActiveAdmin.register Species do
  menu false

  actions :create, :show, :edit, :index

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations])
    end
  end

  filter :id, as: :select
  filter :name, as: :select
  filter :species_class, as: :select
  filter :species_family, as: :select
  filter :species_kingdom, as: :select
  filter :scientific_name, as: :select
  filter :cites_status, as: :select
  filter :iucn_status, as: :select
end

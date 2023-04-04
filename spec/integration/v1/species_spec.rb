require "rails_helper"

module V1
  describe "Species", type: :request do
    it_behaves_like "jsonapi-resources", Species, {
      route_key: "species",
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: ->(i) { "#{i} species" }
      }
    }
  end
end

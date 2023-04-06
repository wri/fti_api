require "rails_helper"

module V1
  describe "Categories", type: :request do
    it_behaves_like "jsonapi-resources", Category, {
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: ->(i) { "#{i} name" }
      }
    }
  end
end

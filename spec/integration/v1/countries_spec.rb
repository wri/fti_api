require "rails_helper"

module V1
  describe "Countries", type: :request do
    it_behaves_like "jsonapi-resources", Country, {
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: ->(i) { "#{i} name" }
      },
      filter: {
        filters: [
          {attributes: {is_active: true}},
          {attributes: {is_active: false}}
        ]
      }
    }
  end
end

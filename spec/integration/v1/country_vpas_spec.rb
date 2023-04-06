require "rails_helper"

module V1
  describe "CountryVpas", type: :request do
    it_behaves_like "jsonapi-resources", CountryVpa, {
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: ->(i) { "#{i} name" }
      },
      route_key: "country-vpas"
    }
  end
end

require 'rails_helper'

module V1
  describe 'CountryLinks', type: :request do
    it_behaves_like "jsonapi-resources", CountryLink, {
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} name" }
      },
      route_key: 'country-links'
    }
  end
end

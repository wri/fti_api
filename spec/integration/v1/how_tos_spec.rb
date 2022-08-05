require 'rails_helper'

module V1
  describe 'HowTos', type: :request do
    it_behaves_like "jsonapi-resources", HowTo, {
      translations: {
        locales: [:en, :fr],
        attributes: { name: 'Name', description: 'Description' }
      },
      sort: {
        attribute: :position,
        sequence: -> (i) { i }
      },
      route_key: 'how-tos'
    }
  end
end

require 'rails_helper'

module V1
  describe 'Donor', type: :request do
    it_behaves_like "jsonapi-resources", Donor, {
      translations: {
        locales: [:en, :fr],
        attributes: { name: 'Donor name', description: 'Donor description' }
      },
    }
  end
end

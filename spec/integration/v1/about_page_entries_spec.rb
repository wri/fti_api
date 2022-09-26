require 'rails_helper'

module V1
  describe 'AboutPageEntry', type: :request do
    it_behaves_like "jsonapi-resources", AboutPageEntry, {
      translations: {
        locales: [:en, :fr],
        attributes: { title: 'Title', body: 'Body' }
      },
      route_key: 'about-page-entries'
    }
  end
end

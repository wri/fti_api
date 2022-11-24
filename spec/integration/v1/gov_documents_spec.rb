require 'rails_helper'

module V1
  describe 'GovDocuments', type: :request do
    it_behaves_like "jsonapi-resources", GovDocument, {
      show: {},
      pagination: {},
      route_key: 'gov-documents'
    }
  end
end

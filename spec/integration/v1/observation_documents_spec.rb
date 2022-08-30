require 'rails_helper'

module V1
  describe 'Observation Documents', type: :request do
    it_behaves_like "jsonapi-resources", ObservationDocument, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { name: 'Document one' },
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { name: 'Document one' },
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} document name" }
      },
      route_key: 'observation-documents'
    }
  end
end

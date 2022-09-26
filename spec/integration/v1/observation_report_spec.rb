require 'rails_helper'

module V1
  describe 'Observation Reports', type: :request do
    it_behaves_like "jsonapi-resources", ObservationReport, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { title: 'Report one' },
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { title: 'Report one' },
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :title,
        sequence: -> (i) { "#{i} report name" }
      },
      route_key: 'observation-reports'
    }
  end
end

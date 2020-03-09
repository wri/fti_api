require 'rails_helper'

module V1
  describe 'Observer', type: :request do
    it_behaves_like "jsonapi-resources", Observer, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { name: 'Monitor one', 'observer-type': 'Mandated' },
        invalid_params: { name: '', 'observer-type': 'Mandated' },
        error_attributes: [422, 100, { name: ["can't be blank"] }]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { name: 'Monitor one', 'observer-type': 'Mandated' },
        invalid_params: { name: '', 'observer-type': 'Mandated' },
        error_attributes: [422, 100, { name: ["can't be blank"] }]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} observer" }
      }
    }
  end
end

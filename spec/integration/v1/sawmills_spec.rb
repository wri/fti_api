require "rails_helper"

module V1
  describe "Sawmills", type: :request do
    it_behaves_like "jsonapi-resources", Sawmill, {
      show: {
        success_roles: %i[admin]
      },
      create: {
        success_roles: %i[operator_user],
        failure_roles: %i[user],
        valid_params: {name: "Example sawmill", lng: 34.5, lat: 44.56},
        invalid_params: {lng: 23.43, lat: 33.22},
        error_attributes: [422, 100, {name: ["can't be blank"]}]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[ngo],
        valid_params: {name: "Example sawmill", lng: 34.5, lat: 44.56},
        invalid_params: {lng: 23.44, lat: 33.22, name: nil},
        error_attributes: [422, 100, {name: ["can't be blank"]}]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {
        success_roles: %i[admin]
      },
      sort: {
        success_roles: %i[admin],
        attribute: :name,
        sequence: ->(i) { "#{i} name" }
      }
    }
  end
end

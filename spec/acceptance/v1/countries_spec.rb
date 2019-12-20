require 'rails_helper'

module V1
  describe 'Countries', type: :request do
    it_behaves_like "jsonapi-resources", Country, {
      show: {},
      create: {
        success_role: :admin,
        failure_role: :user,
        valid_params: { name: 'Country one', iso: 'COO' },
        invalid_params: { name: 'Country one', iso: '' },
        error_attributes: [422, 100, { iso: ["can't be blank"] }]
      },
      edit: {
        success_role: :admin,
        failure_role: :user,
        valid_params: { name: 'Country one', iso: 'COO' },
        invalid_params: { name: 'Country one', iso: '' },
        error_attributes: [422, 100, { iso: ["can't be blank"] }]
      },
      delete: {
        success_role: :admin,
        failure_role: :ngo
      },
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} name" }
      },
      filter: {
        filters: [
          { attributes: { is_active: true } },
          { attributes: { is_active: false } }
        ]
      }
    }
  end
end

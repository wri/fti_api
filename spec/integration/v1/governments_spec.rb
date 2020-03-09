require 'rails_helper'

module V1
  describe 'Governments', type: :request do
    it_behaves_like "jsonapi-resources", Government, {
      show: {
        success_roles: %i[admin],
      },
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { 'government-entity': 'Government one' },
        invalid_params: { 'government-entity': '' },
        error_attributes: [422, 100, { 'government-entity': ["can't be blank"] }]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[ngo],
        valid_params: { 'government-entity': 'Government one' },
        invalid_params: { 'government-entity': '' },
        error_attributes: [422, 100, { 'government-entity': ["can't be blank"] }]
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
        attribute: :government_entity,
        sequence: -> (i) { "#{i} government" }
      },
      filter: {
        success_roles: %i[admin],
        filters: [
          { attributes: { country_id: FactoryBot.create(:country).id } }
        ]
      }
    }
  end
end

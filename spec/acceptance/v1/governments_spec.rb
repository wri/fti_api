require 'rails_helper'

module V1
  describe 'Governments', type: :request do
    it_behaves_like "jsonapi-resources", Government, {
      show: {
        success_role: :admin,
      },
      create: {
        success_role: :admin,
        failure_role: :user,
        valid_params: { 'government-entity': 'Government one' },
        invalid_params: { 'government-entity': '' },
        error_attributes: [422, 100, { 'government-entity': ["can't be blank"] }]
      },
      edit: {
        success_role: :admin,
        failure_role: :ngo,
        valid_params: { 'government-entity': 'Government one' },
        invalid_params: { 'government-entity': '' },
        error_attributes: [422, 100, { 'government-entity': ["can't be blank"] }]
      },
      delete: {
        success_role: :admin,
        failure_role: :user
      },
      pagination: {
        success_role: :admin
      },
      sort: {
        success_role: :admin,
        attribute: :government_entity,
        sequence: -> (i) { "#{i} government" }
      },
      filter: {
        success_role: :admin,
        filters: [
          { attributes: { country_id: FactoryBot.create(:country).id } }
        ]
      }
    }
  end
end

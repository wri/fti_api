require 'rails_helper'

module V1
  describe 'Law', type: :request do
    let(:subcategory) { create(:subcategory) }
    let(:country) { create(:country) }

    it_behaves_like "jsonapi-resources", Law, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[operator],
        valid_params: -> { { 'min-fine': 1, 'max-fine': 2, relationships: { subcategory: subcategory.id, country: country.id } } },
        invalid_params: -> { { 'min-fine': 1, 'max-fine': -2, relationships: { subcategory: subcategory.id } } },
        error_attributes: [
          422,
          100,
          {
            'relationships_country': ['must exist'],
            'max-fine': ["must be greater than or equal to 0"]
          }
        ]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: { 'min-fine': 1, 'max-fine': 2 },
        invalid_params: { 'min-fine': 1, 'max-fine': -2 },
        error_attributes: [422, 100, { 'max-fine': ["must be greater than or equal to 0"] }]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagintaion: {}
    }
  end
end

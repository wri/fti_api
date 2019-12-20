require 'rails_helper'

module V1
  describe 'Law', type: :request do
    it_behaves_like "jsonapi-resources", Law, {
      show: {},
      create: {
        success_role: :admin,
        failure_role: :operator,
        valid_params: { 'min-fine': 1, 'max-fine': 2 },
        invalid_params: { 'min-fine': 1, 'max-fine': -2 },
        error_attributes: [422, 100, { 'max-fine': ["must be greater than or equal to 0"] }]
      },
      edit: {
        success_role: :admin,
        failure_role: :user,
        valid_params: { 'min-fine': 1, 'max-fine': 2 },
        invalid_params: { 'min-fine': 1, 'max-fine': -2 },
        error_attributes: [422, 100, { 'max-fine': ["must be greater than or equal to 0"] }]
      },
      delete: {
        success_role: :admin,
        failure_role: :user
      },
      pagintaion: {}
    }
  end
end

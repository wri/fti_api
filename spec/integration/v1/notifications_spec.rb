require 'rails_helper'

module V1
  describe 'Notifications', type: :request do
    it_behaves_like "jsonapi-resources", Notification, {
      show: {
        show: false,
        success_roles: %i[operator_user]
      }
    }
  end
end

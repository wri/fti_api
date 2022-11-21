# frozen_string_literal: true

module V1
  class UserPermissionResource < BaseResource
    caching

    attributes :user_id, :user_role, :permissions
  end
end

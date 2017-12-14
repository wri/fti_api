# frozen_string_literal: true

module V1
  class UserPermissionResource < JSONAPI::Resource
    caching

    attributes :user_id, :user_role, :permissions

    def custom_links(_)
      { self: nil }
    end
  end
end

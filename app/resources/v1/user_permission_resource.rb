module V1
  class UserPermissionResource < JSONAPI::Resource
    attributes :user_id, :user_role, :permissions
  end
end

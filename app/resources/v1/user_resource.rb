module V1
  class UserResource < JSONAPI::Resource
    attributes :name, :email, :nickname, :institution,
               :is_active, :deactivated_at, :web_url,
               :permissions_request, :permissions_accepted

    has_one :country
    has_one    :user_permission
    has_many   :comments
  end
end

# frozen_string_literal: true

module V1
  class UserResource < JSONAPI::Resource
    caching
    attributes :name, :email, :nickname, :institution,
               :is_active, :deactivated_at, :web_url,
               :permissions_request, :permissions_accepted, :password, :password_confirmation

    has_one :country
    has_one    :user_permission, foreign_key_on: :related
    has_many   :comments
    has_one :observer
    has_one :operator


    def self.fields
      super - [:password, :password_confirmation]
    end

    filters :is_active, :email, :name, :nickname, :institution

    def custom_links(_)
      { self: nil }
    end
  end
end

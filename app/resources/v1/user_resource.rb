# frozen_string_literal: true

module V1
  class UserResource < BaseResource
    caching
    attributes :name, :email, :institution,
      :is_active, :deactivated_at, :web_url, :locale,
      :permissions_request, :permissions_accepted, :password, :password_confirmation

    has_one :country
    has_one :user_permission, foreign_key_on: :related
    has_many :comments
    has_many :managed_observers, class_name: "Observer"
    has_one :observer
    has_one :operator

    def self.fields
      super - [:password, :password_confirmation]
    end

    filters :is_active, :email, :name, :institution
  end
end

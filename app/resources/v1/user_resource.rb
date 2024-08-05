# frozen_string_literal: true

module V1
  class UserResource < BaseResource
    caching
    attributes :name, :first_name, :last_name, :email,
      :is_active, :deactivated_at, :locale, :organization_account,
      :permissions_request, :permissions_accepted, :password, :password_confirmation

    has_one :country
    has_one :user_permission, foreign_key_on: :related
    has_many :managed_observers, class_name: "Observer"
    has_one :observer
    has_one :operator

    def self.fields
      super - [:password, :password_confirmation]
    end

    filters :is_active, :email, :name

    def fetchable_fields
      return super if owner? || admin_user?
      return [:id, :name, :first_name, :last_name, :organization_account, :email] if password_reset_action?

      [:id, :name, :first_name, :last_name, :organization_account]
    end

    private

    def password_reset_action?
      context[:action] == "update" && context[:controller] == "v1/passwords"
    end

    def owner?
      context[:current_user].present? && context[:current_user].id == @model.id
    end
  end
end

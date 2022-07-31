# frozen_string_literal: true

module V1
  class Notification < JSONAPI::Resource
    include CacheableByCurrentUser
    caching

    attributes :dismissed_at, :operator_document_name, :expiration_date, :url

    def self.records(options = {})
      user = @context[:current_user]
      return Notification.none unless user

      # We update the last displayed at when showing the notification
      Notification.visible.current.where(user: user).update_all(last_displayed_at: Time.now) # rubocop:disable Rails/SkipsModelValidations
      Notification.visible.current.where(user: user)
    end

    private

    def self.updatable_fields(context)
      super - [:operator_document_name, :expiration_date, :url]
    end

    def operator_document_name
      @model.operator_document.required_operator_document.name
    end

    def expiration_date
      @model.operator_document.expire_date
    end

    def url
      operator_document_path(@model.operator_document.id)
    end
  end
end

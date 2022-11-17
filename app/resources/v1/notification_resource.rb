# frozen_string_literal: true

module V1
  class NotificationResource < BaseResource
    include CacheableByCurrentUser
    caching

    attributes :operator_document_name, :fmu_name, :expiration_date, :operator_document_id, :notification_name

    def self.records(options = {})
      user = options.dig(:context, :current_user)
      return Notification.none unless user

      # We update the last displayed at when showing the notification
      Notification.visible.current.where(user: user).update_all(last_displayed_at: Time.now) # rubocop:disable Rails/SkipsModelValidations
      Notification.visible.current.where(user: user)
    end

    def operator_document_name
      @model.operator_document.required_operator_document.name
    end

    def fmu_name
      @model.operator_document.fmu&.name
    end

    def expiration_date
      @model.operator_document.expire_date
    end

    def notification_name
      @model.notification_group&.name
    end
  end
end

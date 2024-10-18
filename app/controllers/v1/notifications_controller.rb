# frozen_string_literal: true

module V1
  class NotificationsController < APIController
    load_and_authorize_resource class: "Notification"

    def dismiss
      @notification.update!(dismissed_at: Time.zone.now)
      head :ok
    end
  end
end

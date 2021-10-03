# frozen_string_literal: true

class ScheduleExpirationEmailsJob < ApplicationJob
  queue_as :scheduled_tasks

  def perform
    # ScheduleExpirationEmailsJob.set(wait_until: Time.now + 1.day).perform_later
    ExpirationNotifierService.new.call
  end
end

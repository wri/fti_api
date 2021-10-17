# frozen_string_literal: true

class ScheduleExpirationEmailsJob < ApplicationJob
  queue_as :scheduled_tasks

  def perform
    ExpirationNotifierService.new.call
  end
end

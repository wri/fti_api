# frozen_string_literal: true

class SendExpirationEmailJob < ApplicationJob
  queue_as :expiration_emails

  def perform(operator, documents)
    MailService.new.notify_operator_expired_document(operator, documents).deliver
  end
end

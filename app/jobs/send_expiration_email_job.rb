# frozen_string_literal: true

class SendExpirationEmailJob < ApplicationJob
  queue_as :expiration_emails

  def perform(operator, documents)
    MailService.notify_operator_expired_document(operator, documents)
  end
end

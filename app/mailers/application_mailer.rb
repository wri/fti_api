# frozen_string_literal: true

# Application Mailer
class ApplicationMailer < ActionMailer::Base
  require 'sendgrid-ruby'
  include SendGrid

  default from: 'from@example.com'
  layout 'mailer'

  def send_email(from, to, content, subject, content_type)
    content_type = 'text/plain' if content_type.nil?
    email_from = Email.new(email: from)
    email_to = Email.new(email: to)
    email_content = Content.new(type: content_type, value: content)
    mail = Mail.new(email_from, subject, email_to, email_content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])

    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end

# frozen_string_literal: true

# Application Mailer
class ApplicationMailer < ActionMailer::Base
  require 'sendgrid-ruby'
  include SendGrid

  default from: 'from@example.com'
  layout 'mailer'

  def send_email(from, to, content, subject, type)
    content_type = type || 'text/plain'
    email_from = Email.new(email: from)
    email_to = Email.new(email: Rails.env.production? ? to : ENV['RESPONSIBLE_EMAIL'])
    email_content = Content.new(type: content_type, value: content)
    mail = Mail.new(email_from, subject, email_to, email_content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])

    # TODO: this should be refactored to use SMTP so I will not bother with trying to test it
    return if Rails.env.test?

    response = sg.client.mail._('send').post(request_body: mail.to_json)
    if response.status_code.to_i < 200 || response.status_code.to_i >= 300
      raise "Sendgrid Error: status_code #{response.status_code}, message: #{response.body}"
    end

    response
  end
end

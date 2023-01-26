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
    emails_to = Array.wrap(Rails.env.production? ? to : ENV['RESPONSIBLE_EMAIL'])
    email_content = Content.new(type: content_type, value: content)

    mail = Mail.new
    mail.from = email_from
    mail.subject = subject
    mail.add_content(email_content)
    personalization = Personalization.new

    # send multiple emails alawys as bcc
    if emails_to.count > 1
      emails_to.each { |email| personalization.add_bcc(Email.new(email: email)) }
    else
      personalization.add_to(Email.new(email: emails_to[0]))
    end
    mail.add_personalization(personalization)

    # TODO: this should be refactored to use SMTP so I will not bother with trying to test it
    return if Rails.env.test?
    return if Rails.env.development? && ENV['SEND_EMAILS_IN_DEV'] != 'true'

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])

    response = sg.client.mail._('send').post(request_body: mail.to_json)
    if response.status_code.to_i < 200 || response.status_code.to_i >= 300
      raise "Sendgrid Error: status_code #{response.status_code}, message: #{response.body}"
    end

    response
  end
end

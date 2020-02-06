# frozen_string_literal: true

# Service to deal with emails
class MailService
  def self.notify_user_creation(user)
    text =
<<~TXT
  A new USER has been created through the portal and required approval.
  It has the ID "#{user.id}" and the email "#{user.email}".
  You can now validate it in the backoffice.
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], ENV['CONTACT_EMAIL'], text, "New USER created: #{user.email}"
  end

  def self.notify_operator_creation(operator)
    text =
<<~TXT
  A new OPERATOR has been created through the portal and requires approval.
  It has the ID "#{operator.id}" and the name "#{operator.name}"
  You can now validate it in the backoffice.
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], ENV['CONTACT_EMAIL'], text, "New OPERATOR created: #{operator.name}"
  end

  def self.notify_user_acceptance(user)
    text =
<<~TXT
  Hello #{user.name},

  Your user has been accepted on OTP. You can now use it to login.

  Best,
  Open Timber Portal
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], user.email, text, 'New operator created'
  end
end
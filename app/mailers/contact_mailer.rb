# frozen_string_literal: true

class ContactMailer < AsyncMailer
  def welcome_email(email, name)
    @name      = name
    @email     = email

    @subject = 'Welcome to OTP'

    mail(to: @email, subject: @subject)
  end
end

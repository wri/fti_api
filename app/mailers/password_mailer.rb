# frozen_string_literal: true

class PasswordMailer < AsyncMailer
  def password_email(user_name, user_email, reset_url)
    @name      = user_name
    @email     = user_email
    @reset_url = reset_url

    @subject = 'Requested link to change your password'

    mail(to: @email, subject: @subject)
  end
end

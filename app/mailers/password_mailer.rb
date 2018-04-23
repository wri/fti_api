# frozen_string_literal: true

class PasswordMailer < AsyncMailer
  def password_email(user_name, user_email, reset_url)

    text =
        "Dear #{user_name}\n
Someone has requested a link to change your password. You can do this through the link below.\n
#{reset_url}.\n
If you didn't request this, please ignore this email.\n
Your password won't change until you access the link above and create a new one."

    send_email(ENV['CONTACT_EMAIL'], user_email, text, 'Requested link to change your password')
  end
end
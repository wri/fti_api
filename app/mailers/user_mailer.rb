class UserMailer < ApplicationMailer
  def forgotten_password(user)
    @reset_url = ENV['RECOVER_URL'] + '?reset_password_token=' + generate_reset_token(user)
    @user = user
    mail(to: user.email, subject: 'Requested link to change your password')
  end

  def user_acceptance(user)
    @user = user
    mail(to: user.email, subject: 'New operator created') # TODO: weird subject
  end

  private

  def generate_reset_token(user)
    raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
    @token = raw
    user.update(reset_password_token: hashed, reset_password_sent_at: DateTime.now)
    user.reset_password_token
  end
end

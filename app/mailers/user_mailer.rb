class UserMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def forgotten_password(user)
    @reset_url = generate_reset_url(user)
    @user = user
    mail(
      to: user.email,
      subject: I18n.t("user_mailer.forgotten_password.subject"),
      tracking_settings: {
        click_tracking: {
          enable: false,
          enable_text: false
        }
      }
    )
  end

  def user_acceptance(user)
    @user = user
    mail(to: user.email, subject: I18n.t("user_mailer.user_acceptance.subject"))
  end

  private

  def generate_reset_url(user)
    return edit_user_password_url(reset_password_token: generate_reset_token(user)) if user.admin?

    ENV["FRONTEND_URL"] + "/reset-password?reset_password_token=" + generate_reset_token(user)
  end

  def generate_reset_token(user)
    token, hashed = Devise.token_generator.generate(User, :reset_password_token)
    user.update(reset_password_token: hashed, reset_password_sent_at: DateTime.now)
    token
  end
end

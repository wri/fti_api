class SystemMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default to: ENV["CONTACT_EMAIL"]

  def user_created(user)
    @user = user
    @user_role = {"operator" => "producer", "government" => "monitor"}[user.user_permission.user_role] || user.user_permission.user_role
    mail(subject: I18n.t("system_mailer.user_created.subject"))
  end

  def operator_created(operator)
    @operator = operator
    mail(subject: I18n.t("system_mailer.operator_created.subject"))
  end

  def heartbeat
    mail(
      to: "#{ENV["HEALTHCHECKS_ACCOUNT_ID"]}+#{Rails.env}-email-heartbeat@hc-ping.com",
      subject: "OTP API email heartbeat", # rubocop:disable Rails/I18nLocaleTexts
      body: "Email heartbeat sent at #{Time.zone.now.iso8601}.",
      content_type: "text/plain"
    )
  end
end

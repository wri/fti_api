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
end

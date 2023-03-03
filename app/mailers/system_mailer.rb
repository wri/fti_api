class SystemMailer < ApplicationMailer
  default to: ENV['CONTACT_EMAIL']

  def user_created(user)
    @user = user
    mail(subject: "New USER created: #{user.email}")
  end

  def operator_created(operator)
    @operator = operator
    mail(subject: "New OPERATOR created: #{operator.name}")
  end
end

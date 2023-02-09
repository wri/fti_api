class SystemMailerPreview < ActionMailer::Preview
  def user_created
    SystemMailer.user_created User.last
  end

  def operator_created
    SystemMailer.operator_created Operator.last
  end
end

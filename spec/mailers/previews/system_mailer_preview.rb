class SystemMailerPreview < ActionMailer::Preview
  def user_created
    SystemMailer.user_created User.with_user_role("operator").last
  end

  def operator_created
    SystemMailer.operator_created Operator.last
  end
end

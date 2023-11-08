class UserMailerPreview < ActionMailer::Preview
  def user_acceptance_observer
    UserMailer.user_acceptance User.with_user_role("ngo").last
  end

  def user_acceptance_operator
    UserMailer.user_acceptance User.with_user_role("operator").last
  end

  def forgotten_password
    UserMailer.forgotten_password User.last
  end
end

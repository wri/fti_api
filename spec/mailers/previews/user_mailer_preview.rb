class UserMailerPreview < ActionMailer::Preview
  def user_acceptance
    UserMailer.user_acceptance User.last
  end

  def forgotten_password
    UserMailer.forgotten_password User.last
  end
end

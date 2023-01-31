class UserMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def user_acceptance
    UserMailer.user_acceptance build(:user)
  end

  def forgotten_password
    UserMailer.forgotten_password User.last
  end
end

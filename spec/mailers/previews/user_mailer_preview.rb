class UserMailerPreview < ActionMailer::Preview
  def user_acceptance_observer
    UserMailer.user_acceptance test_user_observer
  end

  def user_acceptance_operator
    UserMailer.user_acceptance test_user_operator
  end

  def forgotten_password
    UserMailer.forgotten_password test_user_operator
  end

  private

  def test_user_observer
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "ngo_manager"))
  end

  def test_user_operator
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "operator"))
  end
end

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

  def inactive_account_warning_observer
    UserMailer.inactive_account_warning test_user_observer, 30.days.from_now.to_date
  end

  def inactive_account_warning_operator
    UserMailer.inactive_account_warning test_user_operator, 30.days.from_now.to_date
  end

  def inactive_account_warning_admin
    UserMailer.inactive_account_warning test_user_admin, 30.days.from_now.to_date
  end

  def account_deactivated_for_inactivity
    UserMailer.account_deactivated_for_inactivity test_user_operator
  end

  private

  def test_user_admin
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "admin"))
  end

  def test_user_observer
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "ngo_manager"))
  end

  def test_user_operator
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "operator"))
  end
end

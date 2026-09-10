class DeviseMailerPreview < ActionMailer::Preview
  def unlock_instructions
    DeviseMailer.unlock_instructions test_user, "faketoken"
  end

  private

  def test_user
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "operator"))
  end
end

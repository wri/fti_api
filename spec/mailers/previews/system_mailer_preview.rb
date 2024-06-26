class SystemMailerPreview < ActionMailer::Preview
  def user_created
    SystemMailer.user_created test_user
  end

  def operator_created
    SystemMailer.operator_created test_operator
  end

  private

  def test_user
    User.new(id: 1, email: "john@example.com", operator: test_operator, country: country, first_name: "John", last_name: "Tester", locale: "en", user_permission: UserPermission.new(user_role: "operator"))
  end

  def test_operator
    Operator.new(id: 161, name: "IFO / Interholco", slug: "ifo-interholco", country: country)
  end

  def country
    Country.new(name: "Congo")
  end
end

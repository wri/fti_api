class SystemMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def user_created
    SystemMailer.user_created build(:user)
  end

  def operator_created
    operator = build(:operator)
    operator.id = 1
    SystemMailer.operator_created(operator)
  end
end

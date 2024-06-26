class OperatorMailerPreview < ActionMailer::Preview
  def quarterly_newsletter
    OperatorMailer.quarterly_newsletter operator, test_user
  end

  private

  def test_user
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en")
  end

  def operator
    Operator.find(operator_id)
  end

  def operator_id
    operators_with_expired = OperatorDocument.doc_expired.pluck(:operator_id).uniq
    operators_with_active_users = User.filter_actives.pluck(:operator_id).uniq

    (operators_with_expired & operators_with_active_users).first
  end
end

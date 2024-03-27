class OperatorMailerPreview < ActionMailer::Preview
  def quarterly_newsletter
    OperatorMailer.quarterly_newsletter operator, operator.all_users.filter_actives.first
  end

  private

  def operator
    Operator.find(operator_id)
  end

  def operator_id
    operators_with_expired = OperatorDocument.doc_expired.pluck(:operator_id).uniq
    operators_with_active_users = User.filter_actives.pluck(:operator_id).uniq

    (operators_with_expired & operators_with_active_users).first
  end
end

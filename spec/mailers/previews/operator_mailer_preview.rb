class OperatorMailerPreview < ActionMailer::Preview
  def expiring_documents_notifications
    OperatorMailer.expiring_documents_notifications operator, documents
  end

  def quarterly_newsletter
    OperatorMailer.quarterly_newsletter operator, operator.users.filter_actives.first
  end

  private

  def documents
    OperatorDocument.where(operator_id: operator_id).to_expire(1.month.from_now)
  end

  def operator
    Operator.find(operator_id)
  end

  def operator_id
    OperatorDocument.to_expire(1.month.from_now).pluck(:operator_id).take(1).first
  end
end

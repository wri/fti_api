class OperatorMailerPreview < ActionMailer::Preview
  def quarterly_newsletter
    OperatorMailer.quarterly_newsletter operator, operator.users.filter_actives.first
  end

  def expiring_documents
    OperatorMailer.expiring_documents operator, operator.users.filter_actives.first, documents_expiring
  end

  def expired_documents
    OperatorMailer.expired_documents operator, operator.users.filter_actives.first, documents_expired
  end

  private

  def documents_expired
    OperatorDocument.where(operator_id: operator_id).doc_expired.last(3)
  end

  def documents_expiring
    OperatorDocument.where(operator_id: operator_id).to_expire(1.month.from_now)
  end

  def documents
    OperatorDocument.where(operator_id: operator_id).to_expire(1.month.from_now)
  end

  def operator
    Operator.find(operator_id)
  end

  def operator_id
    operators_with_expired = OperatorDocument.doc_expired.pluck(:operator_id).uniq
    operators_with_expiring = OperatorDocument.to_expire(1.month.from_now).pluck(:operator_id).uniq

    (operators_with_expired & operators_with_expiring).first
  end
end

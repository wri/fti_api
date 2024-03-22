class OperatorMailerPreview < ActionMailer::Preview
  def quarterly_newsletter
    OperatorMailer.quarterly_newsletter operator, operator.all_users.filter_actives.first
  end

  def expiring_documents
    OperatorMailer.expiring_documents operator, operator.all_users.filter_actives.first, documents_expiring
  end

  def expired_documents
    OperatorMailer.expired_documents operator, operator.all_users.filter_actives.first, documents_expired
  end

  def document_valid
    OperatorMailer.document_valid OperatorDocument.doc_valid.last, User.filter_actives.first
  end

  def document_invalid
    OperatorMailer.document_invalid OperatorDocument.doc_invalid.where.not(document_file: nil).last, User.filter_actives.first
  end

  private

  def documents_expired
    OperatorDocument.where(operator_id: operator_id).doc_expired.last(3)
  end

  def documents_expiring
    documents_expired.each { |d| d.expire_date = 30.days.from_now } # workaround just in preview
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

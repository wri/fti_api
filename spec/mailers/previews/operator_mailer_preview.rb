class OperatorMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def expiring_documents_notifications
    OperatorMailer.expiring_documents_notifications operator, documents
  end

  def quarterly_newsletter
    OperatorMailer.quarterly_newsletter operator
  end

  private

  def documents
    OperatorDocument.where(operator_id: operator_id).to_expire(Date.today)
  end

  def operator
    Operator.find(operator_id)
  end

  def operator_id
    OperatorDocument.to_expire(Date.today).pluck(:operator_id).take(1).first
  end
end

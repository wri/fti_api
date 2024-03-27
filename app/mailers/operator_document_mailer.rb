class OperatorDocumentMailer < ApplicationMailer
  def expiring_documents(operator, user, documents)
    @documents = documents.sort_by { |d| [d.fmu&.name || "_", d.required_operator_document.name] }
    @user = user
    @operator = operator

    mail to: user.email, subject: I18n.t("operator_document_mailer.expiring_documents.subject")
  end

  def expired_documents(operator, user, documents)
    @documents = documents.sort_by { |d| [d.fmu&.name || "_", d.required_operator_document.name] }
    @user = user
    @operator = operator

    mail to: user.email, subject: I18n.t("operator_document_mailer.expired_documents.subject", count: @documents.count)
  end

  def document_valid(document, user)
    @operator = document.operator
    @document = document
    @user = user
    mail to: user.email, subject: I18n.t("operator_document_mailer.document_valid.subject")
  end

  def document_invalid(document, user)
    @operator = document.operator
    @document = document
    @user = user
    mail to: user.email, subject: I18n.t("operator_document_mailer.document_invalid.subject")
  end
end

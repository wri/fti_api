class OperatorDocumentAnnexMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

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

  def admin_document_pending(document, admin)
    @operator = document.operator
    @document = document
    mail to: admin.email, subject: I18n.t("operator_document_mailer.admin_document_pending.subject", company: @operator.name)
  end
end

class OperatorDocumentAnnexMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def document_valid(document, user)
    assign_document(document)
    @user = user
    mail to: user.email, subject: I18n.t("operator_document_annex_mailer.document_valid.subject")
  end

  def document_invalid(document, user)
    assign_document(document)
    @user = user
    mail to: user.email, subject: I18n.t("operator_document_annex_mailer.document_invalid.subject")
  end

  def admin_document_pending(document, admin)
    assign_document(document)
    mail to: admin.email, subject: I18n.t("operator_document_annex_mailer.admin_document_pending.subject", company: @operator.name)
  end

  private

  def assign_document(document)
    @document = document
    @operator_document = document.related_operator_document
    @operator = @operator_document.operator
  end
end

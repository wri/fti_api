class OperatorDocumentMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def expiring_documents(operator, user, documents)
    @documents = sort_documents(documents)
    @user = user
    @operator = operator

    mail to: user.email, subject: I18n.t("operator_document_mailer.expiring_documents.subject")
  end

  def expired_documents(operator, user, documents)
    @documents = sort_documents(documents)
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

  def document_accepted_as_not_required(document, user)
    @operator = document.operator
    @document = document
    @user = user
    mail to: user.email, subject: I18n.t("operator_document_mailer.document_accepted_as_not_required.subject")
  end

  def document_invalid(document, user)
    @operator = document.operator
    @document = document
    @user = user
    mail to: user.email, subject: I18n.t("operator_document_mailer.document_invalid.subject")
  end

  def admin_document_pending(document)
    @operator = document.operator
    @document = document
    # TODO: must be admins but first need to implement admin responsible for countries features
    mail to: ENV["CONTACT_EMAIL"], subject: I18n.t("operator_document_mailer.admin_document_pending.subject", company: @operator.name)
  end

  private

  def sort_documents(documents)
    documents.sort_by { |d| [d.fmu&.name || "_", d.required_operator_document.name] }
  end
end

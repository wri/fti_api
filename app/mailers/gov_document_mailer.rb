class GovDocumentMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def expiring_documents(country, user, documents)
    @documents = sort_documents(documents)
    @user = user
    @country = country

    mail to: user.email, subject: I18n.t("gov_document_mailer.expiring_documents.subject")
  end

  def expired_documents(country, user, documents)
    @documents = sort_documents(documents)
    @user = user
    @country = country

    mail to: user.email, subject: I18n.t("gov_document_mailer.expired_documents.subject", count: @documents.count)
  end

  private

  def sort_documents(documents)
    documents.sort_by { |d| d.required_gov_document.name }
  end
end

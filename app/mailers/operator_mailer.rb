class OperatorMailer < ApplicationMailer
  include ActionView::Helpers::DateHelper

  def expiring_documents_notifications(operator, documents)
    num_documents = documents.count
    expire_date = documents.first.expire_date
    if expire_date > Date.today
      # expiring documents
      time_to_expire = distance_of_time_in_words(expire_date, Date.today)
      subject = t("backend.mail_service.expiring_documents.title", count: num_documents) +
        time_to_expire
      text = [t("backend.mail_service.expiring_documents.text", company_name: operator.name, count: num_documents)]
      text << time_to_expire
      documents.each { |document| text << "<br><a href='#{document_admin_url(document)}'>#{document&.required_operator_document&.name}</a>" }
      text << t("backend.mail_service.expiring_documents.salutation")
    else
      # expired documents
      subject = t("backend.mail_service.expired_documents.title", count: num_documents)
      text = [t("backend.mail_service.expired_documents.text", company_name: operator.name, count: num_documents)]
      documents.each { |document| text << "<br><a href='#{document_admin_url(document)}'>#{document&.required_operator_document&.name}</a>" }
      text << t("backend.mail_service.expired_documents.salutation")
    end

    mail to: operator.email,
      subject: subject,
      body: text.join(""),
      content_type: "text/html"
  end

  # An email that contains the a quarterly report of an operator
  # It lists:
  # 1. Current transparency score
  # 2. Change of score in the last quarter
  # 3. List of documents expiring in the next quarter
  # It's sent every quarter to all users of an operator
  #
  # TODO: Currently we don't have a way to know the language of the operator, so we send it in both French and English
  # In the future this should be refactored:
  # 1. To send it in the language of the user and use I18n
  # 2. To send it using the html template
  def quarterly_newsletter(operator)
    current_score = operator.score_operator_document
    last_score = operator.score_operator_documents.at_date(Date.today - 3.months).order(:date).last
    expiring_docs = operator.operator_documents.to_expire(Date.today + 3.months)

    subject = "Your quarterly OTP report / Votre rapport trimestriel sur l'OTP"

    current_score_percentage = begin
      NumberHelper.float_to_percentage(current_score.all)
    rescue
      0
    end

    text_en = ["Dear OTP user,", ""]
    text_fr = ["Cher utilisateur de l'OTP,", ""]
    text_en << ["Your current score is #{current_score_percentage}.", ""]
    text_fr << ["Votre score actuel est de #{current_score_percentage}.", ""]

    if last_score.present?
      last_score_percentage = begin
        NumberHelper.float_to_percentage(last_score.all)
      rescue
        0
      end

      score_change = NumberHelper.float_to_percentage(current_score.all - last_score.all)
      text_en << ["Your score on #{localized_date(:en, last_score.date)} was #{last_score_percentage}. This means a variation of #{score_change}.", ""]
      text_fr << ["Votre dernier score le #{localized_date(:fr, last_score.date)} était de #{last_score_percentage}. Cela signifie une variation de #{score_change}.", ""]
    end

    if expiring_docs.any?
      text_en << ["Please note that the following documents on your profile are expiring this quarter and will need to be updated:"]
      text_fr << ["Veuillez noter que les documents ci-dessous expirent ce trimestre et qu’il faudra les mettre à jour :"]
      expiring_docs.each do |document|
        text_en << "- #{document.required_operator_document.name} expires on #{localized_date(:en, document.expire_date)}."
        text_fr << "- #{document.required_operator_document.name} expire le #{localized_date(:fr, document.expire_date)}."
      end
      text_en << "You can update these documents by logging on to your OTP profile at www.opentimberportal.org<br>"
      text_fr << "Vous pouvez actualiser ces documents directement sur votre profil, en vous connectant sur l'OTP: www.opentimberportal.org<br>"
    end

    text_en << ["", "Best,", "OTP Team", ""]
    text_fr << ["", "Cordialement,", "L'équipe OTP", ""]

    body = text_en.join("<br>")
    body << "<br>----------------------------------------------------<br>"
    body << text_fr.join("<br>")

    mail bcc: operator.users.pluck(:email).join(", "),
      subject: subject,
      body: body,
      content_type: "text/html"
  end

  private

  def document_admin_url(document)
    ENV["APP_URL"] + Rails.application.routes.url_helpers.url_for(
      {
        controller: "admin/operator_documents",
        action: "show",
        id: document.id,
        only_path: true
      }
    )
  end

  # Temporary helper method to display the date localized.
  # TODO: Remove this when using the user's locale for the email
  def localized_date(locale, date)
    I18n.with_locale(locale) { I18n.l(date, format: :standard) }
  end
end

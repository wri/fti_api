# frozen_string_literal: true

# Service to deal with emails
class MailService
  include ActionView::Helpers::TranslationHelper
  include ActionView::Helpers::DateHelper

  attr_reader :from, :to, :subject, :body, :content_type

  def initialize; end

  def deliver
    AsyncMailer.new.send_email @from, @to, @body, @subject, @content_type
  end

  def forgotten_password(user_name, email, reset_url)
    @subject = 'Requested link to change your password'
    @body =
    <<~TXT
      Dear #{user_name}

      Someone has requested a link to change your password. You can do this through the link below.

      #{reset_url}.

      If you didn't request this, please ignore this email.
      Your password won't change until you access the link above and create a new one.

      Best regards,
      OTP
    TXT
    @from = ENV['CONTACT_EMAIL']
    @to = email

    self
  end

  def notify_user_creation(user)
    @body =
<<~TXT
  A new USER has been created through the portal and required approval.
  It has the ID "#{user.id}", the name "#{user.name}", and the email "#{user.email}".
  You can now validate it in the backoffice.
TXT
    @to = ENV['CONTACT_EMAIL']
    @from = ENV['CONTACT_EMAIL']
    @subject = "New USER created: #{user.email}"

    self
  end

  def notify_operator_creation(operator)
    @body =
<<~TXT
  A new OPERATOR has been created through the portal and requires approval.
  It has the ID "#{operator.id}" and the name "#{operator.name}"
  You can now validate it in the backoffice.
TXT
    @to = ENV['CONTACT_EMAIL']
    @from = ENV['CONTACT_EMAIL']
    @subject = "New OPERATOR created: #{operator.name}"

    self
  end

  def notify_user_acceptance(user)
    @body =
<<~TXT
  Hello #{user.name},

  Your user has been accepted on OTP. You can now use it to login.

  Best,
  Open Timber Portal
TXT
    @from = ENV['CONTACT_EMAIL']
    @to = user.email
    @subject = 'New operator created'

    self
  end

  def self.notify_observers_status_changed(observer, observation)
    observer.users.each do |user|
      MailService.new.notify_observer_status_changed(observer, observation, user).deliver
    end
  end

  def notify_observer_status_changed(observer, observation, user)
    infractor_text = if observation.observation_type == 'government'
                       t('backend.mail_service.observer_status_changed.government')
                     else
                       t('backend.mail_service.observer_status_changed.producers') + "#{observation.operator&.name}"
                     end

    @body = t('backend.mail_service.observer_status_changed.text',
              id: observation.id, observer: observer.name, status: observation.validation_status,
              status_fr: I18n.t("activerecord.enums.observation.statuses.#{observation.validation_status}", locale: :fr),
              date: observation.publication_date, infractor_text: infractor_text,
              infraction: observation.subcategory&.name,
              infraction_fr: Subcategory.with_translations(:fr).where(id: observation.subcategory_id).pluck(:name)&.first)
    @from = ENV['CONTACT_EMAIL']
    @to = user.email
    @subject = t('backend.mail_service.observer_status_changed.subject')

    self
  end

  def notify_admin_published(observation)
    @subject = 'The operator responded to your requested changes'
    @body =
<<~TXT
  Hello,

  #{observation.operator&.name} has responded to your requested changes.
  The status is now: #{observation.validation_status}.

  Please check it in the backoffice.
TXT

    @from = ENV['CONTACT_EMAIL']
    @to = observation.responsible_admin.email

    self
  end

  def notify_responsible(observation)
    @subject = "Observation created with id #{observation.id} / Observation créée avec l'id #{observation.id}"
    @body =
<<~TXT
  Hello,

  The observation with the id #{observation.id} is ready for QC.
  Please check it in the back office.

  Info:
  - Country: #{observation.country&.name}.
  - Observer: #{observation.modified_user&.observer&.name}
  - User
    -Name: #{observation.modified_user&.name}
    -Email: #{observation.modified_user&.email}

  Best,
  OTP
  --------------------------------------------------------------

  Bonjour,

  L'observation avec l'identifiant #{observation.id} est prête pour le contrôle qualité.
   Veuillez le vérifier dans le back-office.

   Info:
   - Pays : #{observation.country&.name}.
   - Observateur : #{observation.modified_user&.observer&.name}
   - Utilisateur
     -Nom : #{observation.modified_user&.name}
     -Email : #{observation.modified_user&.email}

  Cordialement,
   OTP
TXT
    @from = ENV['CONTACT_EMAIL']
    @to = ENV['RESPONSIBLE_EMAIL']

    self
  end

  # Send an email to the operator notifying that there are documents  expired or about to expire
  # @param [Operator] operator
  # @param [Array] documents the documents for which to notify
  def notify_operator_expiring_document(operator, documents)
    num_documents = documents.count
    expire_date = documents.first.expire_date
    if expire_date > Date.today
      # expiring documents
      time_to_expire = distance_of_time_in_words(expire_date, Date.today)
      subject = t('backend.mail_service.expiring_documents.title', count: num_documents) +
        time_to_expire
      text = [t('backend.mail_service.expiring_documents.text', company_name: operator.name, count: num_documents)]
      text << time_to_expire
      documents.each { |document|  text << "<br><a href='#{document_admin_url(document)}'>#{document&.required_operator_document&.name}</a>" }
      text << t('backend.mail_service.expiring_documents.salutation')
    else
      # expired documents
      subject = t('backend.mail_service.expired_documents.title', count: num_documents)
      text = [t('backend.mail_service.expired_documents.text', company_name: operator.name, count: num_documents)]
      documents.each { |document|  text << "<br><a href='#{document_admin_url(document)}'>#{document&.required_operator_document&.name}</a>" }
      text << t('backend.mail_service.expired_documents.salutation')
    end

    @from = ENV['CONTACT_EMAIL']
    @to = operator.email
    @body = text.join('')
    @subject = subject
    @content_type = "text/html"

    self
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

    subject = "Your OTP quarterly report. / Votre rapport trimestriel de OTP."

    current_score_percentage = NumberHelper.float_to_percentage(current_score.all) rescue 0

    text_en = ["Your current score is #{current_score_percentage}."]
    text_fr = ["Votre score actuel est de #{current_score_percentage}."]

    if last_score.present?
      last_score_percentage = NumberHelper.float_to_percentage(last_score.all) rescue 0

      score_change = NumberHelper.float_to_percentage(current_score.all - last_score.all)
      text_en << "Your score on #{last_score.date} was #{last_score_percentage}. This means a variation of #{score_change}."
      text_fr << "Votre dernier score en #{last_score.date} était de #{last_score_percentage}. Cela signifie une variation de #{score_change}."
    end

    expiring_docs.each do |document|
      text_en << "Document #{document.required_operator_document.name} expires on #{document.expire_date}."
      text_fr << "Le document #{document.required_operator_document.name} expire en #{document.expire_date}."
    end

    text_en << ['', 'Best,', 'OTP Team', '']
    text_fr << ['', 'Cordialement,', "L'équipe OTP", '']

    body = text_en.join("<br>")
    body << "<br>----------------------------------------------------<br>"
    body << text_fr.join("<br>")

    @from = ENV['CONTACT_EMAIL']
    @to = operator.users.pluck(:email)
    @body = body
    @subject = subject
    @content_type = "text/html"

    self
  end

  private

  def document_admin_url(document)
    ENV['APP_URL'] + Rails.application.routes.url_helpers.url_for(
      {
        controller: "admin/operator_documents",
        action: "show",
        id: document.id,
        only_path: true
      }
    )
  end
end

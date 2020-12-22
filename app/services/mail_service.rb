# frozen_string_literal: true

# Service to deal with emails
class MailService
  include ActionView::Helpers::TranslationHelper
  include ActionView::Helpers::DateHelper

  attr_reader :from, :to, :subject, :body

  def initialize; end

  def deliver
    AsyncMailer.new.send_email @from, @to, @body, @subject
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

  def newsletter(user_email)
    @subject = 'Registration confirmation'
    @body =
<<~TXT
  Thank you for subscribing to the Open Timber Portal (OTP) newsletter. 
  
  Best wishes,
  The OTP team.
TXT
    @from = ENV['CONTACT_EMAIL']
    @to = user_email

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
    @subject = "Observation created with id #{observation.id}"
    @body =
<<~TXT
  Hello,
  
  The observation with the id #{observation.id} is ready for QC.
  Please check it in the back office.

  Info:
  - Country: #{observation.country&.name}.
  - Observer: #{observation.observer&.name}
  - User 
    -Name: #{observation.modified_user_id&.name}
    -Email: #{observation.modified_user_id&.email}
  
  Best,
  OTP
TXT
    @from = ENV['CONTACT_EMAIL']
    @to = ENV['RESPONSIBLE_EMAIL']

    self
  end

  # Send an email to the operator notifying that there are documents abouts to expire
  # @param [Operator] operator
  # @param [Array] documents the documents for which to notify
  def notify_operator_expired_document(operator, documents)
    num_documents = documents.count
    time_to_expire = distance_of_time_in_words(documents.first.expire_date, Date.tomorrow)
    subject = t('backend.mail_service.expire_documents.title', count: num_documents) +
      time_to_expire
    text = [t('backend.mail_service.expire_documents.text')]
    documents.each { |d|  text << "#{d&.required_operator_document&.name}" }
    text << t('backend.mail_service.expire_documents.salutation')

    @from = ENV['CONTACT_EMAIL']
    @to = operator.email
    @body = text.join('\n')
    @subject = subject

    self
  end
end

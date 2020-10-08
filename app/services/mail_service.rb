# frozen_string_literal: true

# Service to deal with emails
class MailService
  extend ActionView::Helpers::TranslationHelper
  include ActionView::Helpers::TranslationHelper
  include ActionView::Helpers::DateHelper

  attr_reader :from, :to, :subject, :text

  def initialize
  end

  def send
    AsyncMailer.new.send_mail @from, @to, @text, @subject
  end

  def self.forgotten_password(user_name, email, reset_url)
    subject = 'Requested link to change your password'
    body =
    <<~TXT
      Dear #{user_name}
      
      Someone has requested a link to change your password. You can do this through the link below.
      
      #{reset_url}.
      
      If you didn't request this, please ignore this email.
      Your password won't change until you access the link above and create a new one.
      
      Best regards,
      OTP
    TXT
    
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], email, body, subject
  end

  def self.newsletter(user_email)
    subject = 'Registration confirmation'
    body =
<<~TXT
  Thank you for subscribing to the Open Timber Portal (OTP) newsletter. 
  
  Best wishes,
  The OTP team.
TXT
    # Text user
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], user_email, body, subject
  end

  def self.notify_user_creation(user)
    text =
<<~TXT
  A new USER has been created through the portal and required approval.
  It has the ID "#{user.id}", the name "#{user.name}", and the email "#{user.email}".
  You can now validate it in the backoffice.
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], ENV['CONTACT_EMAIL'], text, "New USER created: #{user.email}"
  end

  def self.notify_operator_creation(operator)
    text =
<<~TXT
  A new OPERATOR has been created through the portal and requires approval.
  It has the ID "#{operator.id}" and the name "#{operator.name}"
  You can now validate it in the backoffice.
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], ENV['CONTACT_EMAIL'], text, "New OPERATOR created: #{operator.name}"
  end

  def self.notify_user_acceptance(user)
    text =
<<~TXT
  Hello #{user.name},

  Your user has been accepted on OTP. You can now use it to login.

  Best,
  Open Timber Portal
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], user.email, text, 'New operator created'
  end

  def self.notify_observer_status_changed(observer, observation)
    infractor_text = if observation.observation_type == 'government'
                       t('backend.mail_service.observer_status_changed.government')
                     else
                       t('backend.mail_service.observer_status_changed.producers') + "#{observation.operator&.name}"
                     end

    text = t('backend.mail_service.observer_status_changed.text',
             id: observation.id, observer: observer.name, status: observation.validation_status,
             status_fr: I18n.t("activerecord.enums.observation.statuses.#{observation.validation_status}", locale: :fr),
             date: observation.publication_date, infractor_text: infractor_text,
             infraction: observation.subcategory&.name,
             infraction_fr: Subcategory.with_translations(:fr).where(id: observation.subcategory_id).pluck(:name)&.first)
    observer.users.each do |user|
      AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], user.email, text,
                                 t('backend.mail_service.observer_status_changed.subject')
    end
  end

  def self.notify_admin_published(observation)
    subject = 'The operator responded to your requested changes'
    text =
<<~TXT
  Hello,
  
  #{observation.operator&.name} has responded to your requested changes.
  The status is now: #{observation.validation_status}.
  
  Please check it in the backoffice.
TXT

    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], observation.responsible_admin.email, text, subject
  end

  def self.notify_responsible(observation)
    subject = "Observation created with id #{observation.id}"
    text =
<<~TXT
  Hello,
  
  The observation with the id #{observation.id} is ready for QC.
  Please check it in the back office.
  
  Best,
  OTP
TXT
    AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], ENV['RESPONSIBLE_EMAIL'], text, subject
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
    @text = text.join('\n')
    @subject = subject
  end
end

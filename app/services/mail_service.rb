# frozen_string_literal: true

# Service to deal with emails
class MailService
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
  It has the ID "#{user.id}" and the email "#{user.email}".
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
                       "Type: Government"
                     else
                       "Producers: #{observation.operator&.name}"
                     end

    text =
<<~TXT
  Hello #{observer.name},

  There has been an update of status for an observation you made.
  The status is now #{observation.validation_status}.

  Observation details:
  
  Date: #{observation.publication_date}
  #{infractor_text}
  Infraction: #{observation.subcategory&.name}
 
  Best,
   Open Timber Portal
TXT
    observer.users.each do |user|
      AsyncMailer.new.send_email ENV['CONTACT_EMAIL'], user.email, text, 'Observation has been updated'
    end
  end
end

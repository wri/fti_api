class ObservationMailer < ApplicationMailer
  def observation_created(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def observation_submitted_for_qc(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def observation_needs_revision(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def observation_ready_for_publication(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def observation_published(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def admin_observation_ready_for_qc(observation, user)
    @observation = observation
    @observer = observation.modified_user.observer
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def admin_observation_published_not_modified(observation, user)
    @observation = observation
    @observer = observation.modified_user.observer
    mail to: user.email, subject: I18n.t(subject_i18n_key, observer: @observer.name, id: observation.id)
  end

  private

  def observer
    @observation.modified_user.observer
  end

  def subject_i18n_key
    "observation_mailer.#{action_name}.subject"
  end
end

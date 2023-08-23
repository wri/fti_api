class ObservationMailer < ApplicationMailer
  def observation_created(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t("observation_mailer.observation_created.subject", id: observation.id)
  end

  def observation_submitted_for_qc(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t("observation_mailer.observation_submitted_for_qc.subject", id: observation.id)
  end

  def observation_needs_revision(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t("observation_mailer.observation_needs_revision.subject", id: observation.id)
  end

  def observation_ready_for_publication(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t("observation_mailer.observation_ready_for_publication.subject", id: observation.id)
  end

  def observation_published(observation, user)
    @user = user
    @observation = observation
    mail to: user.email, subject: I18n.t("observation_mailer.observation_published.subject", id: observation.id)
  end

  def notify_admin_observation_published(observation)
    @observation = observation
    @observer = observation.modified_user.observer
    mail to: observation.responsible_admin.email,
      subject: I18n.t("observation_mailer.notify_admin_observation_published.subject", id: observation.id)
  end

  def admin_observation_ready_for_qc(observation)
    @observation = observation
    @observer = observation.modified_user.observer
    mail to: observation.responsible_admin.email,
      subject: I18n.t("observation_mailer.admin_observation_ready_for_qc.subject", id: observation.id)
  end

  def admin_observation_published_not_modified(observation)
    @observation = observation
    @observer = observation.modified_user.observer
    mail to: observation.responsible_admin.email,
      subject: I18n.t("observation_mailer.admin_observation_published_not_modified.subject", observer: @observer.name, id: observation.id)
  end
end

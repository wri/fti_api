class ObservationMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

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
    @observer = observer
    @link = start_qc_link(observation, user)
    mail to: user.email, subject: I18n.t(subject_i18n_key, id: observation.id)
  end

  def admin_observation_published_not_modified(observation, user)
    @observation = observation
    @observer = observer
    mail to: user.email, subject: I18n.t(subject_i18n_key, observer: @observer.name, id: observation.id)
  end

  private

  def start_qc_link(observation, user)
    return "#{ENV["OBSERVATIONS_TOOL_URL"]}/private/observations/edit/#{observation.id}" if user.observation_tool_user?

    start_qc_admin_observation_url(@observation)
  end

  def observer
    @observation.modified_user&.observer || @observation.user&.observer || @observation.observers.first
  end

  def subject_i18n_key
    "observation_mailer.#{action_name}.subject"
  end
end

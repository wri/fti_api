class ObservationMailerPreview < ActionMailer::Preview
  def admin_observation_published_not_modified
    ObservationMailer.admin_observation_published_not_modified admin_observation
  end

  def admin_observation_ready_for_qc
    ObservationMailer.admin_observation_ready_for_qc admin_observation
  end

  def observation_created
    ObservationMailer.observation_created observation, User.last
  end

  def observation_submitted_for_qc
    ObservationMailer.observation_submitted_for_qc observation, User.last
  end

  def observation_needs_revision
    ObservationMailer.observation_needs_revision observation, User.last
  end

  def observation_ready_for_publication
    ObservationMailer.observation_ready_for_publication observation, User.last
  end

  def observation_published
    ObservationMailer.observation_published observation, User.last
  end

  private

  def admin_observation
    Observation
      .where.not(observation_report: nil)
      .where.not(monitor_comment: [nil, ""])
      .where.not(responsible_admin: nil)
      .last
  end

  def observation
    Observation
      .where.not(observation_report: nil)
      .where.not(admin_comment: [nil, ""])
      .last
  end
end

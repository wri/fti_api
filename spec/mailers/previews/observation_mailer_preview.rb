class ObservationMailerPreview < ActionMailer::Preview
  def admin_observation_published_not_modified
    ObservationMailer.admin_observation_published_not_modified observation, test_user
  end

  def admin_observation_ready_for_qc
    ObservationMailer.admin_observation_ready_for_qc observation, test_user
  end

  def observation_created
    ObservationMailer.observation_created observation, test_user
  end

  def observation_submitted_for_qc
    ObservationMailer.observation_submitted_for_qc observation, test_user
  end

  def observation_needs_revision
    ObservationMailer.observation_needs_revision observation, test_user
  end

  def observation_ready_for_publication
    ObservationMailer.observation_ready_for_publication observation, test_user
  end

  def observation_published
    ObservationMailer.observation_published observation, test_user
  end

  private

  def observation
    Observation.new(
      id: 100,
      observation_type: "operator",
      subcategory: Subcategory.new(name: "Conflict of interest - inter or intra agency"),
      admin_comment: "Here are some comments made by admin",
      monitor_comment: "Here are some comments made by monitor",
      observation_report: ObservationReport.new(title: "Report 100"),
      modified_user: test_user
    )
  end

  def test_user
    User.new(id: 1, email: "john@example.com", observer: Observer.new(name: "Test Observer"), name: "John Tester", locale: "en", user_permission: UserPermission.new(user_role: "ngo_manager"))
  end
end

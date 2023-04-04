class ResponsibleAdminMailerPreview < ActionMailer::Preview
  def observation_ready_to_qc
    ResponsibleAdminMailer.observation_ready_to_qc Observation.where(validation_status: "Ready for QC").last
  end
end

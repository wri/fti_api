class ObservationMailerPreview < ActionMailer::Preview
  def notify_admin_published
    ObservationMailer.notify_admin_published Observation.published.where("responsible_admin_id is not null and operator_id is not null").last
  end
end

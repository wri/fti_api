class ObservationMailerPreview < ActionMailer::Preview
  def notify_admin_published
    ObservationMailer.notify_admin_published Observation.published.where.not(responsible_admin: nil, operator: nil).last
  end
end

class ObservationMailer < ApplicationMailer
  def notify_admin_published(observation)
    @observation = observation
    mail to: observation.responsible_admin.email,
      subject: "The operator responded to your requested changes"
  end
end

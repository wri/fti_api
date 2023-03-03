class ResponsibleAdminMailer < ApplicationMailer
  default to: ENV['RESPONSIBLE_EMAIL']

  def observation_ready_to_qc(observation)
    @observation = observation
    mail(subject: "Observation created with id #{observation.id} / Observation créée avec l'id #{observation.id}")
  end
end

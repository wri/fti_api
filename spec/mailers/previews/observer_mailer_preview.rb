class ObserverMailerPreview < ActionMailer::Preview
  def observation_status_changed
    ObserverMailer.observation_status_changed(Observer.last, User.last, Observation.last)
  end
end

class ObserverMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def observation_status_changed
    ObserverMailer.observation_status_changed(Observer.last, build(:user), Observation.last)
  end
end

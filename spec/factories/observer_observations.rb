FactoryGirl.define do
  factory :observer_observation do
    after(:build) do |random_observer_observation|
      random_observer_observation.observer ||= FactoryGirl.create(:observer)
      random_observer_observation.observation ||= FactoryGirl.create(:observation)
    end
  end
end

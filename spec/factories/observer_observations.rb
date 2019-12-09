FactoryBot.define do
  factory :observer_observation do
    after(:build) do |random_observer_observation|
      random_observer_observation.observer ||= FactoryBot.create(:observer)
      random_observer_observation.observation ||= FactoryBot.create(:observation)
    end
  end
end

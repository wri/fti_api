FactoryBot.define do
  factory :observation_report_observer do
    after(:build) do |random_observation_report_observer|
      random_observation_report_observer.observer ||= FactoryBot.create(:observer)
      random_observation_report_observer.observation_report ||=
        FactoryBot.create(:observation_report)
    end
  end
end

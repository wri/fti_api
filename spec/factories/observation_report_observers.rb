FactoryGirl.define do
  factory :observation_report_observer do
    after(:build) do |random_observation_report_observer|
      random_observation_report_observer.observer ||= FactoryGirl.create(:observer)
      random_observation_report_observer.observation_report ||=
        FactoryGirl.create(:observation_report)
    end
  end
end

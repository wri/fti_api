FactoryGirl.define do
  factory :observation_operator do
    after(:build) do |random_observation_operator|
      random_observation_operator.operator ||= FactoryGirl.create(:operator)
      random_observation_operator.observation ||= FactoryGirl.create(:observation)
    end
  end
end

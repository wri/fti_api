FactoryBot.define do
  factory :observation_operator do
    after(:build) do |random_observation_operator|
      random_observation_operator.operator ||= FactoryBot.create(:operator)
      random_observation_operator.observation ||= FactoryBot.create(:observation)
    end
  end
end

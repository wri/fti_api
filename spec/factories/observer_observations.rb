# == Schema Information
#
# Table name: observer_observations
#
#  id             :integer          not null, primary key
#  observer_id    :integer
#  observation_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :observer_observation do
    after(:build) do |random_observer_observation|
      random_observer_observation.observer ||= FactoryBot.create(:observer)
      random_observer_observation.observation ||= FactoryBot.create(:observation)
    end
  end
end

# == Schema Information
#
# Table name: observation_operators
#
#  id             :integer          not null, primary key
#  observation_id :integer
#  operator_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :observation_operator do
    after(:build) do |random_observation_operator|
      random_observation_operator.operator ||= FactoryBot.create(:operator)
      random_observation_operator.observation ||= FactoryBot.create(:observation)
    end
  end
end

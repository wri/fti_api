# == Schema Information
#
# Table name: species_observations
#
#  id             :integer          not null, primary key
#  observation_id :integer
#  species_id     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#

FactoryBot.define do
  factory :species_observation do
    after(:build) do |random_species_observation|
      random_species_observation.observation ||= FactoryBot.create :observation
      random_species_observation.species ||= FactoryBot.create :species
    end
  end
end

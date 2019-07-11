FactoryBot.define do
  factory :species_observation do
    after(:build) do |random_species_observation|
      random_species_observation.observation ||= FactoryBot.create :observation
      random_species_observation.species ||= FactoryBot.create :species
    end
  end
end

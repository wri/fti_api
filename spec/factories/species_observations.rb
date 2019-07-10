FactoryGirl.define do
  factory :species_observation do
    after(:build) do |random_species_observation|
      random_species_observation.observation ||= FactoryGirl.create :observation
      random_species_observation.species ||= FactoryGirl.create :species
    end
  end
end

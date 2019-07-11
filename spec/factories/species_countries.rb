FactoryBot.define do
  factory :species_country do
    after(:build) do |random_species_country|
      random_species_country.country ||= FactoryBot.create :country
      random_species_country.species ||= FactoryBot.create :species
    end
  end
end

FactoryGirl.define do
  factory :species_country do
    after(:build) do |random_species_country|
      random_species_country.country ||= FactoryGirl.create :country
      random_species_country.species ||= FactoryGirl.create :species
    end
  end
end

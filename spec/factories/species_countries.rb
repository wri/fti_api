# == Schema Information
#
# Table name: species_countries
#
#  id         :integer          not null, primary key
#  country_id :integer
#  species_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :species_country do
    after(:build) do |random_species_country|
      random_species_country.country ||= FactoryBot.create :country
      random_species_country.species ||= FactoryBot.create :species
    end
  end
end

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

require 'rails_helper'

RSpec.describe SpeciesCountry, type: :model do
  before :each do
    @species = create(:species)
    @country = create(:country, species: [@species])
  end

  it 'Count on country species' do
    expect(@country.species.count).to eq(1)
  end
end

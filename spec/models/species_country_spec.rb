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
  subject(:species_country) { FactoryGirl.build :species_country }

  it 'is valid with valid attributes' do
    expect(species_country).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:country) }
    it { is_expected.to belong_to(:species) }
  end
end

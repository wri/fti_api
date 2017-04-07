# == Schema Information
#
# Table name: species_observations
#
#  id             :integer          not null, primary key
#  observation_id :integer
#  species_id     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe SpeciesObservation, type: :model do
  before :each do
    @species     = create(:species)
    @observation = create(:observation_1, species: [@species])
  end

  it 'Count on observation species' do
    expect(@observation.species.count).to eq(1)
  end
end

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
  subject(:species_observation) { FactoryBot.build(:species_observation) }

  it 'is valid with valid attributes' do
    expect(species_observation).to be_valid
  end
end

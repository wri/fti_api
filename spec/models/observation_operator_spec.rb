require 'rails_helper'

RSpec.describe ObservationOperator, type: :model do
  it 'is valid with valid attributes' do
    observation_operator = build(:observation_operator)
    expect(observation_operator).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:operator) }
    it { is_expected.to belong_to(:observation) }
  end
end

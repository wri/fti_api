require 'rails_helper'

RSpec.describe ObserverObservation, type: :model do
  subject(:observer_observation) { FactoryBot.build(:observer_observation) }

  it 'is valid with valid attributes' do
    expect(observer_observation).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:observer).touch(true) }
    it { is_expected.to belong_to(:observation).touch(true) }
  end
end

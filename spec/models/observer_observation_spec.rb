# == Schema Information
#
# Table name: observer_observations
#
#  id             :integer          not null, primary key
#  observer_id    :integer
#  observation_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#

require 'rails_helper'

RSpec.describe ObserverObservation, type: :model do
  subject(:observer_observation) { FactoryBot.build(:observer_observation) }

  it 'is valid with valid attributes' do
    expect(observer_observation).to be_valid
  end
end

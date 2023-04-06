# == Schema Information
#
# Table name: observation_operators
#
#  id             :integer          not null, primary key
#  observation_id :integer
#  operator_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#

require "rails_helper"

RSpec.describe ObservationOperator, type: :model do
  it "is valid with valid attributes" do
    observation_operator = build(:observation_operator)
    expect(observation_operator).to be_valid
  end
end

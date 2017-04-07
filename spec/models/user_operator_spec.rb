# == Schema Information
#
# Table name: user_operators
#
#  id          :integer          not null, primary key
#  operator_id :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe UserOperator, type: :model do
  before :each do
    @user     = create(:user)
    @operator = create(:operator, users: [@user])
  end

  it 'Count on operator user' do
    expect(@operator.users.count).to eq(1)
  end
end

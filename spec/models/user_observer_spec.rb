# == Schema Information
#
# Table name: user_observers
#
#  id          :integer          not null, primary key
#  observer_id :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe UserObserver, type: :model do
  before :each do
    @user     = create(:user)
    @monitor = create(:observer, users: [@user])
  end

  it 'Count on observer user' do
    expect(@monitor.users.count).to eq(1)
  end
end

# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  email                :string
#  password_digest      :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  nickname             :string
#  name                 :string
#  institution          :string
#  web_url              :string
#  is_active            :boolean          default(TRUE)
#  deactivated_at       :datetime
#  permissions_request  :integer
#  permissions_accepted :datetime
#  country_id           :integer
#

require 'rails_helper'

RSpec.describe User, type: :model do
  before :each do
    @user = create(:user, nickname: 'testuser')
  end

  it 'Users count' do
    expect(User.count).to eq(1)
  end

  it 'Deactivate activate user' do
    @user.deactivate
    expect(User.count).to                  eq(1)
    expect(User.filter_inactives.count).to eq(1)
    expect(@user.deactivated?).to          be(true)
    @user.activate
    expect(@user.activated?).to            be(true)
    expect(User.filter_actives.count).to   be(1)
  end

  it 'User name and nickname validation' do
    @user = User.new(name: '', nickname: '', email: 'user@example.com', password: 'password', password_confirmation: 'password')

    @user.valid?
    expect { @user.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Nickname can't be blank, Nickname is invalid, Name can't be blank")
  end

  it 'Nickname is email validation' do
    @user = User.new(name: 'Test user', nickname: 'blabla@example.com', email: 'user@example.com', password: 'password', password_confirmation: 'password')

    @user.valid?
    expect { @user.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Nickname is invalid')
  end

  it 'Nickname specific validation' do
    @user = User.new(name: 'Test user', nickname: 'admin 333', email: 'user@example.com', password: 'password', password_confirmation: 'password')

    @user.valid?
    expect { @user.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Nickname is invalid')
  end

  it 'Nickname uniqueness validation' do
    @user = User.new(name: 'Test user', nickname: 'Testuser', email: 'user@example.com', password: 'password', password_confirmation: 'password')

    @user.valid?
    expect { @user.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Nickname has already been taken')
  end
end

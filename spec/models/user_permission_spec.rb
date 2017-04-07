# == Schema Information
#
# Table name: user_permissions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  user_role   :integer          default("user"), not null
#  permissions :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe UserPermission, type: :model do
  before :each do
    @user     = create(:user)
    @user_ngo = create(:user, permissions_request: 'ngo')
  end

  let!(:user_permissions) {
    {"user"=>{"id"=>["manage"]}, "observation"=>{"all"=>["read"]}}
  }

  let!(:ngo_permissions) {
    {"user"=>{"id"=>["manage"]}, "observation"=>{"user_id"=>["manage"]}}
  }

  let!(:operator_permissions) {
    {"user"=>{"id"=>["manage"]}, "observation"=>{"all"=>["read"]}}
  }

  let!(:admin_permissions) {
    {"admin"=>{"all"=>["read"]},"all"=>{"all"=>["manage"]}}
  }

  it 'Check default user permissions' do
    expect(@user.user_permission.user_role).to   eq('user')
    expect(@user.user_permission.permissions).to eq(user_permissions)
  end

  it 'Change user permissions and role to admin' do
    @user.user_permission.update(user_role: 'admin', permissions: admin_permissions)

    expect(@user.user_permission.user_role).to   eq('admin')
    expect(@user.user_permission.permissions).to eq(admin_permissions)
  end

  it 'Change user permissions and role to ngo' do
    @user.user_permission.update(user_role: 'ngo', permissions: ngo_permissions)

    expect(@user.user_permission.user_role).to   eq('ngo')
    expect(@user.user_permission.permissions).to eq(ngo_permissions)
  end

  it 'Change user permissions and role to operator' do
    @user.user_permission.update(user_role: 'operator', permissions: operator_permissions)

    expect(@user.user_permission.user_role).to   eq('operator')
    expect(@user.user_permission.permissions).to eq(operator_permissions)
  end

  it 'Change ngo user permissions and role to user' do
    @user_ngo.user_permission.update(user_role: 'ngo',  permissions: ngo_permissions)
    @user_ngo.user_permission.update(user_role: 'user', permissions: user_permissions)

    expect(@user_ngo.user_permission.user_role).to   eq('user')
    expect(@user_ngo.user_permission.permissions).to eq(user_permissions)
  end

  it 'Accept user role request' do
    @user_ngo.user_permission.update(user_role: 'ngo')

    expect(@user_ngo.user_permission.user_role).to   eq('ngo')
    expect(@user_ngo.user_permission.permissions).to eq(ngo_permissions)
  end

  it 'Is a user an user? Show the role name' do
    expect(@user.admin?).to    eq(false)
    expect(@user.user?).to     eq(true)
    expect(@user.role_name).to eq('User')
  end
end

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

require "rails_helper"

RSpec.describe UserPermission, type: :model do
  subject(:user_permission) { FactoryBot.build(:user_permission) }

  it "is valid with valid attributes" do
    expect(user_permission).to be_valid
  end
end

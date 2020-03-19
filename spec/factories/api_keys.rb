# == Schema Information
#
# Table name: api_keys
#
#  id           :integer          not null, primary key
#  access_token :string
#  expires_at   :datetime
#  user_id      :integer
#  is_active    :boolean          default("true")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :api_key do
    sequence(:access_token) { |n| "token-#{n}" }
    expires_at { DateTime.tomorrow }

    before(:create) do |api_key|
      user = FactoryBot.build(:user)
      user.user_permission = UserPermission.new(user_role: 0)
      api_key.user ||= user
    end
  end
end

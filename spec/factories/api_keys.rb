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

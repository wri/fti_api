FactoryBot.define do
  factory :user_permission do
    user_role { 0 }

    after(:build) do |random_user_permission|
      random_user_permission.user ||= FactoryBot.create(:user)
    end
  end
end

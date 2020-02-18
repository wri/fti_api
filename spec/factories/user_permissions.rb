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

FactoryBot.define do
  factory :user_permission do
    user_role { 0 }

    after(:build) do |random_user_permission|
      random_user_permission.user ||= FactoryBot.create(:user)
    end
  end
end

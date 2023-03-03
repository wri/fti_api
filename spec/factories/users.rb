# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#  institution            :string
#  web_url                :string
#  is_active              :boolean          default(TRUE)
#  deactivated_at         :datetime
#  permissions_request    :integer
#  permissions_accepted   :datetime
#  country_id             :integer
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  observer_id            :integer
#  operator_id            :integer
#  holding_id             :integer
#  locale                 :string
#

FactoryBot.define do
  factory :user do
    sequence(:email)    { |n| "pepe#{n}@vizzuality.com" }

    password { 'password' }
    password_confirmation { |u| u.password }
    name { 'Test user' }
    is_active { true }

    transient do
      user_role { :user }
    end

    after(:build) do |random_user, evaluator|
      random_user.user_permission = UserPermission.new(user_role: evaluator.user_role)
    end

    factory :ngo do
      sequence(:email) { |n| "ngo#{n}@vizzuality.com" }

      name { 'Test ngo' }

      after(:build) do |random_ngo|
        random_ngo.observer ||= FactoryBot.create(:observer)
        random_ngo.user_permission = UserPermission.new(user_role: 2)
      end
    end

    factory :operator_user do
      sequence(:email) { |n| "operator#{n}@vizzuality.com" }

      name { 'Test operator' }

      after(:build) do |random_operator|
        random_operator.operator ||= FactoryBot.create(:operator)
        random_operator.user_permission = UserPermission.new(user_role: 1)
      end
    end

    factory :government_user do
      sequence(:email) { |n| "gov#{n}@vizzuality.com" }

      name { 'Test government' }

      after(:build) do |random_gov_user|
        random_gov_user.country ||= FactoryBot.create(:country)
        random_gov_user.user_permission = UserPermission.new(user_role: 'government')
      end
    end

    factory :admin do
      sequence(:email) { |n| Faker::Internet.email }

      name { 'Admin user' }

      after(:build) do |random_admin|
        random_admin.user_permission = UserPermission.new(user_role: 3)
      end

      after(:create) do |user|
        user.regenerate_api_key
      end
    end

    factory :webuser do
      sequence(:email) { |n| "webuser#{n}@vizzuality.com" }

      name { 'Web user' }

      after(:build) do |random_webuser|
        random_webuser.user_permission = UserPermission.new(user_role: 0)
      end

      after(:create) do |user|
        user.regenerate_api_key
      end

      after(:build) do |random_admin|
        random_admin.user_permission = UserPermission.new(user_role: 0)
      end
    end
  end
end

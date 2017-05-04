# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  password_digest        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  nickname               :string
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
#

FactoryGirl.define do
  factory :user do
    sequence(:email)    { |n| "pepe#{n}@vizzuality.com" }
    sequence(:nickname) { |n| "pepe#{n}"                }

    password 'password'
    password_confirmation { |u| u.password }
    name 'Test user'
    is_active true
  end

  factory :ngo, class: User do
    sequence(:email)    { |n| "ngo#{n}@vizzuality.com" }
    sequence(:nickname) { |n| "ngo#{n}"                }

    password 'password'
    password_confirmation { |u| u.password }
    name 'Test ngo'
    is_active true

    after(:create) do |random_ngo|
      random_ngo.user_permission.update(user_role: 'ngo')
    end
  end

  factory :operator_user, class: User do
    sequence(:email)    { |n| "operator#{n}@vizzuality.com" }
    sequence(:nickname) { |n| "operator#{n}"                }

    password 'password'
    password_confirmation { |u| u.password }
    name 'Test operator'
    is_active true

    after(:create) do |random_operator|
      random_operator.user_permission.update(user_role: 'operator')
    end
  end

  factory :admin, class: User do
    sequence(:email)    { |n| "admin#{n}@vizzuality.com" }
    sequence(:nickname) { |n| "admin#{n}"                }

    password 'password'
    password_confirmation { |u| u.password }
    name 'Admin user'
    is_active true

    after(:create) do |random_admin|
      random_admin.user_permission.update(user_role: 'admin')
    end
  end

  factory :webuser, class: User do
    sequence(:email)    { |n| "webuser#{n}@vizzuality.com" }
    sequence(:nickname) { |n| "webuser#{n}"                }

    password 'password'
    password_confirmation { |u| u.password }
    name 'Web user'
    is_active true

    after(:create) do |user|
      user.regenerate_api_key
    end
  end
end

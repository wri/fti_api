# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_type :integer
#

FactoryGirl.define do
  factory :donor do
    sequence(:name) { |n| "#{n} Donor #{Faker::Address.country}" }
  end
end

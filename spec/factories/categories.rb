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
  factory :category do
    sequence(:name) { |n| "#{n} Category #{Faker::Address.country}" }
    category_type { rand(0..1) }
  end
end

# == Schema Information
#
# Table name: contributors
#
#  id             :integer          not null, primary key
#  website        :string
#  logo           :string
#  priority       :integer
#  category       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  type           :string           default("Partner")
#  contributor_id :integer          not null
#  name           :string           not null
#  description    :text
#

FactoryBot.define do
  factory :donor do
    sequence(:name) { |n| "#{n} Donor #{Faker::Address.country}" }
  end
end

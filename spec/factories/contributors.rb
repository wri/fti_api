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
  factory :contributor do
    name { |n| "Contributor#{n}" }
    website { |n| "Website#{n}" }
    priority { rand(0..10) }
  end
end

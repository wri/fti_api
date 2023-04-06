# == Schema Information
#
# Table name: severities
#
#  id             :integer          not null, primary key
#  level          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  subcategory_id :integer
#  details        :text
#

FactoryBot.define do
  factory :severity do
    level { 1 }
    details { "Lorem ipsum.." }

    after(:build) do |random_severity|
      random_severity.subcategory ||= FactoryBot.create(:subcategory)
    end
  end
end

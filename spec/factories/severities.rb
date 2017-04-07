# == Schema Information
#
# Table name: severities
#
#  id             :integer          not null, primary key
#  level          :integer
#  severable_id   :integer          not null
#  severable_type :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryGirl.define do
  factory :severity do
    level   1
    details 'Lorem ipsum..'
  end
end

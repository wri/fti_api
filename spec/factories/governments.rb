# == Schema Information
#
# Table name: governments
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  is_active  :boolean          default(TRUE)
#

FactoryBot.define do
  factory :government do
    country
    government_entity { 'A Government' }
    details { 'Indicator one' }
  end
end

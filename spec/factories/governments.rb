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

FactoryGirl.define do
  factory :government do
    government_entity 'A Government'
    details           'Indicator one'

    after(:create) do |government|
      country_attributes = FactoryGirl.build(:country).attributes.except(%w[id created_at updated_at])
      government.country ||= Country.find_or_create_by(country_attributes)
    end
  end
end

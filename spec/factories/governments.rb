# == Schema Information
#
# Table name: governments
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :government do
    government_entity 'A Government'
    details           'Indicator one'

    after(:create) do |government|
      government.update(country: FactoryGirl.create(:country, name: "Country #{Faker::Lorem.sentence}",
                                                              iso: "C#{Faker::Lorem.sentence}"))
    end
  end
end

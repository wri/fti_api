# == Schema Information
#
# Table name: annex_operators
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :annex_operator do
    illegality 'Illegality one'
    details    'Lorem ipsum..'

    after(:create) do |annex|
      annex.update(country: FactoryGirl.create(:country, name: "Country #{Faker::Lorem.sentence}",
                                                         iso: "C#{Faker::Lorem.sentence}"),
                                                         laws: [FactoryGirl.create(:law)])
    end
  end
end

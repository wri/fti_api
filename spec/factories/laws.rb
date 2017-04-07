# == Schema Information
#
# Table name: laws
#
#  id            :integer          not null, primary key
#  country_id    :integer
#  vpa_indicator :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryGirl.define do
  factory :law do
    legal_reference 'Lorem'
    legal_penalty   'Lorem ipsum..'
    vpa_indicator   'Indicator one'

    after(:create) do |law|
      law.update(country: FactoryGirl.create(:country, name: "Country #{Faker::Lorem.sentence}",
                                                       iso: "C#{Faker::Lorem.sentence}"))
    end
  end
end

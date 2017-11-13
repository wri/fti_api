# == Schema Information
#
# Table name: laws
#
#  id                 :integer          not null, primary key
#  written_infraction :text
#  infraction         :text
#  sanctions          :text
#  min_fine           :integer
#  max_fine           :integer
#  penal_servitude    :string
#  other_penalties    :text
#  apv                :text
#  subcategory_id     :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  country_id         :integer
#  currency           :string
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

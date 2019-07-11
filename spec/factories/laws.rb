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

FactoryBot.define do
  factory :law do
    min_fine { rand(0..10) }
    max_fine { rand(0..10) }

    after(:build) do |law|
      law.subcategory ||= FactoryBot.create :subcategory
      law.country ||= FactoryBot.create :country
    end
  end
end

# == Schema Information
#
# Table name: country_vpas
#
#  id          :integer          not null, primary key
#  url         :string
#  active      :boolean          default(TRUE), not null
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  country_id  :integer
#  name        :string
#  description :text
#
FactoryBot.define do
  factory :country_vpa do
    country

    sequence(:position, &:itself)
    active { true }
    name { "Vpa name" }
    description { "Vpa description" }
    url { "https://example.com" }
  end
end

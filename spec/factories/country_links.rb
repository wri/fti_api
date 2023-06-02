# == Schema Information
#
# Table name: country_links
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
  factory :country_link do
    country

    sequence(:position, &:itself)
    active { true }
    name { "Link name" }
    description { "Link description" }
    url { "https://example.com" }
  end
end

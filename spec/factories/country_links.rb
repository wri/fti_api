FactoryBot.define do
  factory :country_link do
    country

    sequence(:position, &:itself)
    active { true }
    name { 'Link name' }
    description { 'Link description' }
    url { 'https://example.com' }
  end
end

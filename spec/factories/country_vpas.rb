FactoryBot.define do
  factory :country_vpa do
    country

    sequence(:position, &:itself)
    active { true }
    name { 'Vpa name' }
    description { 'Vpa description' }
    url { 'https://example.com' }
  end
end

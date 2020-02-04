FactoryBot.define do
  factory :sawmill do
    sequence(:name) { |n| "Sawmill#{n}"}
    lat { Faker::Address::latitude }
    lng { Faker::Address::longitude }

    after(:build) do |random_sawmill|
      random_sawmill.operator ||= FactoryBot.create :operator
    end
  end
end

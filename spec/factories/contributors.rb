FactoryBot.define do
  factory :contributor do
    name { |n| "Contributor#{n}" }
    website { |n| "Website#{n}" }
    priority { rand(0..10) }
  end
end

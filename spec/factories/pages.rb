FactoryBot.define do
  factory :page do
    title { "Title" }
    sequence(:slug) { |n| "slug-#{n}" }
    body { "Body" }
  end
end

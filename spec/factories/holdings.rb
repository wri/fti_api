FactoryBot.define do
  factory :holding do
    sequence(:name) { |n| "Holding #{n}" }
  end
end

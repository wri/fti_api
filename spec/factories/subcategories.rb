FactoryBot.define do
  factory :subcategory, class: 'Subcategory' do
    sequence(:name) { |n| "Subcategory#{n}" }
    subcategory_type { rand(0..1) }

    after(:build) do |random_subcategory|
      random_subcategory.category ||= FactoryBot.create(:category)
    end
  end
end

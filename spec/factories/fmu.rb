FactoryGirl.define do
  factory :fmu do
    sequence(:name) { |n| "FMU#{n}" }
    forest_type { rand(0..3) }

    after(:build) do |random_fmu|
      random_fmu.country ||= FactoryGirl.create(:country)
    end
  end
end

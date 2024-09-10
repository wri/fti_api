FactoryBot.define do
  factory :quality_control do
    reviewable { create(:observation, validation_status: "QC2 in progress") }
    reviewer { build(:admin) }
    passed { true }

    trait :not_passed do
      passed { false }
      comment { "Quality control not passed" }
    end
  end
end

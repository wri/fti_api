# == Schema Information
#
# Table name: quality_controls
#
#  id              :bigint           not null, primary key
#  reviewable_type :string           not null
#  reviewable_id   :bigint           not null
#  reviewer_id     :bigint           not null
#  passed          :boolean          default(FALSE), not null
#  comment         :text
#  metadata        :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
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

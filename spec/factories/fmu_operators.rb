# == Schema Information
#
# Table name: fmu_operators
#
#  id          :integer          not null, primary key
#  fmu_id      :integer          not null
#  operator_id :integer          not null
#  current     :boolean          not null
#  start_date  :date
#  end_date    :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

FactoryBot.define do
  factory :fmu_operator do
    start_date { Time.zone.today }
    end_date { Date.tomorrow }
    current { true }

    after(:build) do |random_fmu_operator|
      random_fmu_operator.fmu ||= FactoryBot.create(:fmu)
      random_fmu_operator.operator ||= FactoryBot.create(:operator)
    end
  end
end

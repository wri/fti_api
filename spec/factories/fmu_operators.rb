FactoryBot.define do
  factory :fmu_operator do
    start_date { Date.today }
    end_date { Date.tomorrow }
    current { true }

    after(:build) do |random_fmu_operator|
      random_fmu_operator.fmu ||= FactoryBot.create(:fmu)
      random_fmu_operator.operator ||= FactoryBot.create(:operator)
    end
  end
end

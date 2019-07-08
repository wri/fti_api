FactoryGirl.define do
  factory :fmu_operator do
    start_date { Date.today }
    end_date { Date.tomorrow }
    current { true }

    after(:build) do |random_fmu_operator|
      random_fmu_operator.fmu ||= FactoryGirl.create(:fmu)
      random_fmu_operator.operator ||= FactoryGirl.create(:operator)
    end
  end
end

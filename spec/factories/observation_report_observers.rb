# == Schema Information
#
# Table name: observation_report_observers
#
#  id                    :integer          not null, primary key
#  observation_report_id :integer
#  observer_id           :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

FactoryBot.define do
  factory :observation_report_observer do
    after(:build) do |random_observation_report_observer|
      random_observation_report_observer.observer ||= FactoryBot.create(:observer)
      random_observation_report_observer.observation_report ||=
        FactoryBot.create(:observation_report)
    end
  end
end

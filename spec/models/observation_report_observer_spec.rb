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

require "rails_helper"

RSpec.describe ObservationReportObserver, type: :model do
  it "is valid with valid attributes" do
    observation_report_observer = build(:observation_report_observer)
    expect(observation_report_observer).to be_valid
  end
end

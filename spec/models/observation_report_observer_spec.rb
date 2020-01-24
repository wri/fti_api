require 'rails_helper'

RSpec.describe ObservationReportObserver, type: :model do
  it 'is valid with valid attributes' do
    observation_report_observer = build(:observation_report_observer)
    expect(observation_report_observer).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:observer).touch(true) }
    it { is_expected.to belong_to(:observation_report).touch(true) }
  end
end

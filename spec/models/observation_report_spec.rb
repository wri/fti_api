require 'rails_helper'

RSpec.describe ObservationReport, type: :model do
  it 'is valid with valid attributes' do
    observation_report = FactoryBot.build :observation_report
    expect(observation_report).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:user).inverse_of(:observation_reports) }
    it { is_expected.to have_many(:observation_report_observers) }
    it { is_expected.to have_many(:observers).through(:observation_report_observers) }
    it { is_expected.to have_many(:observations) }
  end

  describe 'Hooks' do
    describe '#remove_attachment_id_directory' do
      it 'removes all attached documents' do
        observation_report = FactoryBot.create :observation_report
        filepath = File.join(
          'public',
          'uploads',
          'observation_report',
          'attachment',
          observation_report.id.to_s,
          'image.png'
        )

        expect(File.exist?(filepath)).to eql true

        observation_report.destroy

        expect(File.exist?(filepath)).to eql false
      end
    end
  end
end

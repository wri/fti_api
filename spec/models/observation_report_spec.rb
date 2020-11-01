# == Schema Information
#
# Table name: observation_reports
#
#  id               :integer          not null, primary key
#  title            :string
#  publication_date :datetime
#  attachment       :string
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deleted_at       :datetime
#

require 'rails_helper'

RSpec.describe ObservationReport, type: :model do
  it 'is valid with valid attributes' do
    observation_report = build(:observation_report)
    expect(observation_report).to be_valid
  end

  describe 'Hooks' do
    describe '#remove_attachment_id_directory' do
      it 'removes all attached documents' do
        observation_report = create(:observation_report)
        filepath = File.join "public", observation_report.attachment_url

        expect(File.exist?(filepath)).to eql true

        observation_report.destroy

        expect(File.exist?(filepath)).to eql false
      end
    end
  end
end

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

require "rails_helper"

RSpec.describe ObservationReport, type: :model do
  subject { build(:observation_report) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe "hooks" do
    describe "sync_observation_observers" do
      let!(:observer) { create(:observer) }

      context "when adding observer to report" do
        let!(:report) { create(:observation_report) }
        let!(:observation) { create(:observation, observation_report: report) }

        before do
          report.observers << observer
        end

        it "adds observer to observation" do
          expect(observation.reload.observers).to include(observer)
        end
      end

      context "when removing observer from report" do
        let!(:report) { create(:observation_report, observers: [observer]) }
        let!(:observation) { create(:observation, observers: [observer], observation_report: report) }

        before do
          report.observers.delete(observer)
        end

        it "removes observer from observation" do
          expect(observation.reload.observers).not_to include(observer)
        end
      end
    end
  end

  describe "soft delete" do
    let!(:report) { create(:observation_report) }

    context "when deleting" do
      it "moves attachment to private directory" do
        expect(report.attachment.file.file).to match("/public/uploads")
        report.destroy!
        report.reload
        expect(report.attachment.file.file).to match("/private/uploads")
      end
    end

    context "when restoring" do
      before do
        report.destroy!
        report.reload
      end

      it "moves attachment back to public directory" do
        expect(report.attachment.file.file).to match("/private/uploads")
        report.restore
        report.reload
        expect(report.attachment.file.file).to match("/public/uploads")
      end
    end
  end
end

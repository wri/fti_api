# == Schema Information
#
# Table name: observation_documents
#
#  id                    :integer          not null, primary key
#  name                  :string
#  attachment            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  deleted_at            :datetime
#  document_type         :integer          default("Government Documents"), not null
#  observation_report_id :bigint
#

require "rails_helper"

RSpec.describe ObservationDocument, type: :model do
  subject { build(:observation_document) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe "soft delete" do
    let!(:report) { create(:observation_document) }

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

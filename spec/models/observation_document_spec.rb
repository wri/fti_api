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

  it "is invalid with wrong document_type" do
    subject.document_type = "wrong"
    expect(subject.valid?).to eq(false)
    expect(subject.errors[:document_type]).to include("is not included in the list")
  end

  describe "deletion" do
    let!(:document) { create(:observation_document) }

    context "when soft deleting record" do
      it "does not delete the original file" do
        original_file_path = document.attachment.file.file
        expect(File.exist?(original_file_path)).to be true
        document.destroy!
        expect(document.deleted?).to be true
        expect(File.exist?(original_file_path)).to be true
        expect(document.attachment.file.file).to eq(original_file_path)
      end
    end

    context "when hard deleting record" do
      it "deletes the original file" do
        original_file_path = document.attachment.file.file
        expect(File.exist?(original_file_path)).to be true
        document.really_destroy!
        expect(File.exist?(original_file_path)).to be false
      end
    end
  end
end

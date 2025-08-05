# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  start_date               :date
#  expire_date              :date
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer          not null
#  country_id               :integer          not null
#  user_id                  :integer
#  attachment               :string
#
require "rails_helper"

RSpec.describe GovDocument, type: :model do
  describe "changing attachment" do
    let!(:document) { create(:gov_document, :file) }

    with_versioning do
      context "when removing attachment" do
        it "moves previous attachment to private folder" do
          expect(document.attachment.file.file).to match(Rails.root.join("tmp/uploads").to_s)
          document.remove_attachment!
          document.save!
          document.reload
          expect(document.read_attribute(:attachment)).to be_nil
          prev_version = document.versions.last.reify
          expect(prev_version.attachment.file.file).to match("/private/uploads")
        end
      end

      context "when changing attachment" do
        it "moves previous attachment to private folder" do
          expect(document.attachment.file.file).to match(Rails.root.join("tmp/uploads").to_s)
          document.attachment = Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf"))
          document.save!
          document.reload
          expect(document.read_attribute(:attachment)).to match(".pdf")
          prev_version = document.versions.last.reify
          expect(prev_version.attachment.file.file).to match("/private/uploads")
          expect(prev_version.attachment.file.file).to match(".png")
        end
      end
    end
  end

  describe "Class methods" do
    describe "#expire_documents" do
      let!(:gd) {
        create(
          :gov_document,
          force_status: status,
          expire_date: expire_date
        )
      }

      subject { GovDocument.expire_documents }

      context "when the date is in the past" do
        let(:expire_date) { Time.zone.today - 1.year }

        context "when the status is valid" do
          let(:status) { :doc_valid }

          it { expect { subject }.to change { gd.reload.status }.from("doc_valid").to("doc_expired") }
        end

        context "when the status is pending" do
          let(:status) { :doc_pending }

          it { expect { subject }.to_not change { gd.reload.status } }
        end
      end
      context "when the date is in the future" do
        let(:expire_date) { Time.zone.today + 1.year }
        let(:status) { :doc_valid }

        it { expect { subject }.to_not change { gd.reload.status } }
      end
    end
  end

  describe "soft delete" do
    let!(:document) { create(:gov_document, :file) }

    with_versioning do
      context "when deleting" do
        it "moves attachment to private directory" do
          expect(document.attachment.file.file).to match(Rails.root.join("tmp/uploads").to_s)
          document.destroy!
          document.reload
          expect(document.attachment.file.file).to match("/private/uploads")
        end
      end

      context "when restoring" do
        before do
          # change attachment to move previous to private directory
          document.attachment = Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf"))
          document.save!
          document.destroy!
          document.reload
        end

        it "moves attachment back to public directory" do
          expect(document.attachment.file.file).to match("/private/uploads")
          document.restore
          reloaded_doc = GovDocument.find(document.id) # as reload does not reload paper_trail.live? weird
          expect(reloaded_doc.attachment.file.file).to match(Rails.root.join("tmp/uploads").to_s)
          # first version should stay in private directory
          prev_version = reloaded_doc.versions[-2].reify
          expect(prev_version.attachment.file.file).to match("/private/uploads")
        end
      end
    end
  end
end

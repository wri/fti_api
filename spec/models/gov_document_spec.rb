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
      context "when changing attachment" do
        it "does not delete the original file" do
          original_file_path = document.attachment.file.file
          expect(File.exist?(original_file_path)).to be true
          document.attachment = Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf"))
          document.save!
          expect(File.exist?(original_file_path)).to be true
          expect(document.attachment.file.file).to_not eq(original_file_path)
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

  describe "deletion" do
    let!(:document) { create(:gov_document, :file) }

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

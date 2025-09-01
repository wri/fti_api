require "rails_helper"
require "carrierwave/test/matchers"

RSpec.describe DocumentFileUploader do
  include CarrierWave::Test::Matchers

  let(:operator) { create(:operator) }
  let(:required_operator_document) { create(:required_operator_document_country) }
  let(:operator_document) do
    create(:operator_document_country, operator: operator, required_operator_document: required_operator_document)
  end
  let(:document_file) { operator_document.document_file }
  let(:uploader) { DocumentFileUploader.new(document_file, :attachment) }

  before do
    DocumentFileUploader.enable_processing = true
  end

  after do
    uploader.remove!
    DocumentFileUploader.enable_processing = false
  end

  describe "#filename" do
    context "when model has no operator_document" do
      let(:document_file_without_operator) { create(:document_file) }
      let(:uploader_without_operator) { DocumentFileUploader.new(document_file_without_operator, :attachment) }

      before do
        uploader_without_operator.store!(File.open(Rails.root.join("spec", "support", "files", "doc.pdf")))
      end

      after do
        uploader_without_operator.remove!
      end

      it "returns the original filename when operator_document is nil" do
        expect(uploader_without_operator.filename).to eq("doc.pdf")
      end
    end

    context "when original filename is blank" do
      before do
        allow(uploader).to receive(:original_filename).and_return(nil)
      end

      it "returns nil when original filename is blank" do
        expect(uploader.filename).to be_nil
      end
    end

    context "when model has operator_document" do
      before do
        operator.update!(name: "Test Operator With Very Long Name That Should Be Truncated")
        required_operator_document.update!(name: "Test Required Document With Very Long Name That Should Be Truncated For Filename Safety And Readability")
        uploader.store!(File.open(Rails.root.join("spec", "support", "files", "doc.pdf")))
      end

      it "generates filename with operator name, document name, and date" do
        travel_to Time.zone.parse("2023-06-15") do
          filename = uploader.filename
          expect(filename).to include("test-operator-with-very-long-n")
          expect(filename).to include("test-required-document-with-ve")
          expect(filename).to include("2023-06-15")
          expect(filename).to end_with(".pdf")
        end
      end

      it "preserves file extension from original filename" do
        expect(uploader.filename).to end_with(".pdf")
      end

      it "sanitizes the generated filename" do
        filename = uploader.filename
        expect(filename).not_to include("/")
        expect(filename).not_to include("\\")
        expect(filename).not_to include(":")
        expect(filename).not_to include(";")
      end
    end
  end

  describe "#protected?" do
    context "when owner is nil" do
      let(:document_file) { DocumentFile.find(@document_file_id) }

      before do
        @document_file_id = operator_document.document_file.id
        operator_document.update!(document_file: nil, reason: "have to put somehting in to make valid update")
      end

      it "returns true when owner is nil" do
        expect(uploader.protected?).to be true
      end
    end

    context "when owner exists" do
      before do
        document_file.update!(operator_document: operator_document)
      end

      context "when owner document is publication authorization" do
        before do
          operator_document.required_operator_document.contract_signature = true
          operator_document.required_operator_document.save!(validate: false)
        end

        it "returns true when publication_authorization is true" do
          expect(uploader.protected?).to be true
        end
      end

      context "when owner is not publication authorization" do
        context "when document is valid" do
          before do
            operator_document.update!(status: "doc_valid")
          end

          it "returns false when document is valid" do
            expect(uploader.protected?).to be false
          end
        end

        context "when document is expired" do
          before do
            operator_document.update!(status: "doc_expired")
          end

          it "returns false when document is expired" do
            expect(uploader.protected?).to be false
          end
        end

        context "when document is neither valid nor expired" do
          before do
            operator_document.update!(status: "doc_pending")
          end

          it "returns true when document is neither valid nor expired" do
            expect(uploader.protected?).to be true
          end
        end
      end
    end
  end
end

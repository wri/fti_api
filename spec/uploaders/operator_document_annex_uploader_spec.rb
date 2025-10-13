require "rails_helper"
require "carrierwave/test/matchers"

RSpec.describe OperatorDocumentAnnexUploader do
  include CarrierWave::Test::Matchers

  let(:operator) { create(:operator) }
  let(:required_operator_document) { create(:required_operator_document_country) }
  let(:operator_document) do
    create(:operator_document_country, operator: operator, required_operator_document: required_operator_document)
  end
  let(:operator_document_annex) { create(:operator_document_annex, operator_document: operator_document) }
  let(:uploader) { OperatorDocumentAnnexUploader.new(operator_document_annex, :attachment) }

  before do
    OperatorDocumentAnnexUploader.enable_processing = true
  end

  after do
    uploader.remove!
    OperatorDocumentAnnexUploader.enable_processing = false
  end

  describe "#filename" do
    context "when original filename is blank" do
      before do
        allow(uploader).to receive(:original_filename).and_return(nil)
      end

      it "returns nil when original filename is blank" do
        expect(uploader.filename).to be_nil
      end
    end

    context "when operator_document_annex has attachment" do
      before do
        uploader.store!(File.open(Rails.root.join("spec", "support", "files", "doc.pdf")))
      end

      it "generates filename with Annex prefix, timestamp, and parent document basename" do
        filename = uploader.filename
        timestamp = Time.now.to_i
        expect(filename).to start_with("Annex_#{timestamp}_")
        expect(filename).to end_with(".pdf")
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

      it "truncates basename to 200 characters max" do
        long_name = "a" * 300
        allow_any_instance_of(CarrierWave::SanitizedFile).to receive(:basename).and_return(long_name)
        filename = uploader.filename
        # Remove "Annex_" prefix and timestamp to check the basename part
        basename_part = filename.split("_")[2..].join("_").gsub(".pdf", "")
        expect(basename_part.length).to be <= 200
      end
    end

    context "when operator_document is nil" do
      let(:operator_document_annex) { create(:operator_document_annex, operator_document: nil) }

      before do
        uploader.store!(File.open(Rails.root.join("spec", "support", "files", "doc.pdf")))
      end

      it "uses 'no_document' as suffix when operator_document is nil" do
        filename = uploader.filename
        expect(filename).to include("no_document")
      end
    end
  end

  describe "#protected?" do
    it "delegates to model's needs_authorization_before_downloading? method" do
      expect(operator_document_annex).to receive(:needs_authorization_before_downloading?).and_return(true)
      expect(uploader.protected?).to be true
    end
  end
end

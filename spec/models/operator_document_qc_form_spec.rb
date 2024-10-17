require "rails_helper"

RSpec.describe OperatorDocumentQCForm, type: :model do
  let(:operator_document) { create(:operator_document) }

  describe "validations" do
    it "validates presence of decision" do
      form = OperatorDocumentQCForm.new(operator_document)
      form.valid?
      expect(form.errors[:decision]).to include("can't be blank")
    end

    it "validates inclusion of decision in DECISIONS" do
      form = OperatorDocumentQCForm.new(operator_document, decision: "invalid_decision")
      form.valid?
      expect(form.errors[:decision]).to include("is not included in the list")
    end

    it "validates presence of admin_comment when decision is doc_invalid" do
      form = OperatorDocumentQCForm.new(operator_document, decision: "doc_invalid")
      form.valid?
      expect(form.errors[:admin_comment]).to include("can't be blank")
    end

    it "validates document is in pending state" do
      operator_document.doc_valid!
      form = OperatorDocumentQCForm.new(operator_document, decision: "doc_invalid")
      form.valid?
      expect(form.errors[:operator_document]).to include("is not in pending state")
    end

    it "validates document model" do
      operator_document.start_date = nil
      operator_document.save!(validate: false)
      form = OperatorDocumentQCForm.new(operator_document, decision: "doc_invalid")
      form.valid?
      expect(form.errors[:start_date]).to include("can't be blank")
    end
  end

  describe "#call" do
    it "updates the status and admin_comment of the operator_document" do
      form = OperatorDocumentQCForm.new(operator_document, decision: "doc_invalid", admin_comment: "Rejected")
      form.call
      operator_document.reload
      expect(operator_document.status).to eq("doc_invalid")
      expect(operator_document.admin_comment).to eq("Rejected")
    end

    context "when decision is doc_valid and reason is present" do
      let(:operator_document) { create(:operator_document, document_file: nil, reason: "this document is not required") }

      it "updates the status of the operator_document to doc_not_required" do
        form = OperatorDocumentQCForm.new(operator_document, decision: "doc_valid", admin_comment: "Rejected")
        form.call
        operator_document.reload
        expect(operator_document.status).to eq("doc_not_required")
        expect(operator_document.admin_comment).to eq("Rejected")
      end
    end
  end
end

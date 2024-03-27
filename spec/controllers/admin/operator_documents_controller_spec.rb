require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::OperatorDocumentsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "PUT approve" do
    let(:doc) { create(:operator_document_country, force_status: "doc_pending") }

    before { put :approve, params: {id: doc.id} }

    it "approves document as valid" do
      expect(flash[:notice]).to match("Document approved")
      expect(doc.reload.status).to eq("doc_valid")
    end

    context "document marked by operator as not required" do
      let(:doc) { create(:operator_document_country, force_status: "doc_pending", document_file: nil, reason: "It's a national secret") }

      it "approves document as not required" do
        expect(flash[:notice]).to match("Document approved")
        expect(doc.reload.status).to eq("doc_not_required")
      end
    end
  end

  describe "GET perform_qc" do
    let(:doc) { create(:operator_document_country, force_status: "doc_pending", document_file: nil, reason: "It's a national secret") }

    before { get :perform_qc, params: {id: doc.id} }

    it "is successful" do
      expect(response).to be_successful
    end

    context "when document not pending qc" do
      let(:doc) { create(:operator_document_country, force_status: "doc_valid", document_file: nil, reason: "It's a national secret") }

      it "redirects to index" do
        expect(response).to redirect_to(admin_operator_documents_path)
        expect(flash[:alert]).to match("Document must be in a pending state to start QC")
      end
    end
  end

  describe "PUT perform_qc" do
    let(:doc) { create(:operator_document_country, force_status: "doc_pending", document_file: nil, reason: "It's a national secret") }

    before { put :perform_qc, params: {id: doc.id, operator_document: doc_params} }

    context "when rejecting" do
      let(:doc_params) { {status: "doc_invalid", admin_comment: "Comment"} }

      it "is successful" do
        expect(response).to redirect_to(admin_operator_documents_path)
        expect(flash[:notice]).to match("Document rejected")
        doc.reload
        expect(doc.status).to eq("doc_invalid")
        expect(doc.admin_comment).to eq("Comment")
      end

      context "when missing admin comments" do
        let(:doc_params) { {status: "doc_invalid", admin_comment: ""} }

        it "does not change status" do
          expect(response).to be_successful
          expect(doc.reload.status).to eq("doc_pending")
        end
      end
    end

    context "when approving" do
      let(:doc_params) { {status: "doc_valid"} }

      it "is successful" do
        expect(response).to redirect_to(admin_operator_documents_path)
        expect(flash[:notice]).to match("Document approved")
        doc.reload
        expect(doc.status).to eq("doc_valid")
      end
    end
  end
end

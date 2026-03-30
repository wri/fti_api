require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::OperatorDocumentsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "GET reject" do
    let(:doc) { create(:operator_document_country, force_status: "doc_pending") }

    before { get :reject, params: {id: doc.id}, xhr: true, format: :js }

    it "renders the reject form js" do
      expect(response).to be_successful
    end

    context "when document is not pending" do
      let(:doc) { create(:operator_document_country, force_status: "doc_valid") }

      it "shows a notice and reloads the page" do
        expect(response).to be_successful
        expect(flash[:notice]).to eq(I18n.t("active_admin.operator_documents_page.not_pending"))
      end
    end
  end

  describe "PUT reject" do
    let(:doc) { create(:operator_document_country, force_status: "doc_pending") }

    before { put :reject, params: {id: doc.id, operator_document: {admin_comment: comment}}, xhr: true, format: :js }

    context "with a comment" do
      let(:comment) { "Missing signature" }

      it "rejects the document and redirects" do
        expect(response).to be_successful
        expect(flash[:notice]).to match("Document rejected")
        doc.reload
        expect(doc.status).to eq("doc_invalid")
        expect(doc.admin_comment).to eq("Missing signature")
      end
    end

    context "when document is not pending" do
      let(:doc) { create(:operator_document_country, force_status: "doc_valid") }
      let(:comment) { "Some comment" }

      it "does not change status and redirects" do
        expect(flash[:notice]).to eq(I18n.t("active_admin.operator_documents_page.not_pending"))
        expect(doc.reload.status).to eq("doc_valid")
      end
    end
  end

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
    let(:doc) { create(:operator_document_country, force_status: "doc_pending") }

    before { get :perform_qc, params: {id: doc.id} }

    it "redirects to the document page" do
      expect(response).to redirect_to(admin_operator_document_path(doc))
    end
  end
end

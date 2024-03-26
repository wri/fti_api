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
end

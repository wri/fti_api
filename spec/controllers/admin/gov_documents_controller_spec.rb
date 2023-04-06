require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::GovDocumentsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "PUT approve" do
    let(:doc) { create(:gov_document, force_status: "doc_pending") }

    before { put :approve, params: {id: doc.id} }

    it "approves document as valid" do
      expect(flash[:notice]).to match("Document approved")
      expect(doc.reload.status).to eq("doc_valid")
    end
  end

  describe "PUT reject" do
    let(:doc) { create(:gov_document, force_status: "doc_pending") }

    before { put :reject, params: {id: doc.id} }

    it "rejects document" do
      expect(flash[:notice]).to match("Document rejected")
      expect(doc.reload.status).to eq("doc_invalid")
    end
  end
end

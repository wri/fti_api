require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::OperatorDocumentAnnexesController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "GET reject" do
    let(:annex) { create(:operator_document_annex, force_status: "doc_pending") }

    before { get :reject, params: {id: annex.id}, xhr: true, format: :js }

    it "renders the reject form js" do
      expect(response).to be_successful
    end
  end

  describe "PUT reject" do
    let(:annex) { create(:operator_document_annex, force_status: "doc_pending") }

    before { put :reject, params: {id: annex.id, operator_document_annex: {invalidation_reason: reason}}, xhr: true, format: :js }

    context "with a reason" do
      let(:reason) { "Missing signature" }

      it "rejects the annex and sets notice" do
        expect(response).to be_successful
        expect(flash[:notice]).to match(I18n.t("active_admin.operator_documents_page.rejected"))
        annex.reload
        expect(annex.status).to eq("doc_invalid")
        expect(annex.invalidation_reason).to eq("Missing signature")
      end
    end

    context "without a reason" do
      let(:reason) { nil }

      it "does not reject the annex" do
        expect(flash[:notice]).to be_nil
        expect(annex.reload.status).to eq("doc_pending")
      end
    end
  end

  describe "PUT approve" do
    let(:annex) { create(:operator_document_annex, force_status: "doc_pending") }

    before { put :approve, params: {id: annex.id} }

    it "approves the annex as valid" do
      expect(flash[:notice]).to eq(I18n.t("active_admin.operator_document_annexes_page.approved"))
      expect(annex.reload.status).to eq("doc_valid")
    end

    context "when annex is doc_invalid" do
      let(:annex) { create(:operator_document_annex, force_status: "doc_invalid") }

      it "approves the annex as valid" do
        expect(flash[:notice]).to eq(I18n.t("active_admin.operator_document_annexes_page.approved"))
        expect(annex.reload.status).to eq("doc_valid")
      end
    end
  end
end

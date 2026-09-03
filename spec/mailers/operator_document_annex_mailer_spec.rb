require "rails_helper"

RSpec.describe OperatorDocumentAnnexMailer, type: :mailer do
  let(:operator) { create(:operator) }
  let(:user) { build(:operator_user, operator: operator) }
  let(:operator_document) { create(:operator_document_country, operator: operator) }
  let(:annex) { create(:operator_document_annex, operator_document: operator_document, name: "annex name") }

  shared_examples "renders the related document name" do
    it "renders the headers" do
      expect(mail.to).to eq([user.email])
    end

    it "renders the name of the document the annex is related to" do
      expect(mail.body.encoded).to include(operator_document.name_with_fmu)
    end
  end

  shared_examples "annex mail" do
    include_examples "renders the related document name"

    context "when the annex is only related to the document history" do
      before do
        annex.annex_document.destroy!
        annex.reload
      end

      include_examples "renders the related document name"
    end
  end

  describe "document_valid" do
    let(:mail) { described_class.document_valid(annex, user) }

    include_examples "annex mail"
  end

  describe "document_invalid" do
    let(:annex) {
      create(:operator_document_annex, operator_document: operator_document, name: "annex name",
        force_status: :doc_invalid, invalidation_reason: "Here is the reason why is invalid")
    }
    let(:mail) { described_class.document_invalid(annex, user) }

    include_examples "annex mail"
  end

  describe "admin_document_pending" do
    let(:user) { build(:admin) }
    let(:mail) { described_class.admin_document_pending(annex, user) }

    include_examples "annex mail"
  end
end

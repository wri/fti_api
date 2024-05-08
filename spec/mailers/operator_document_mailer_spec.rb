require "rails_helper"

RSpec.describe OperatorDocumentMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  let(:operator) { create(:operator) }
  let(:user) { build(:operator_user, operator: operator) }

  describe "expiring_documents" do
    let(:country) { create(:country) }
    let(:operator) { create(:operator, country_id: country.id) }
    let(:rod1) { create(:required_operator_document_country, country_id: country.id) }
    let(:rod2) { create(:required_operator_document_country, country_id: country.id) }
    let(:document1) {
      create(:operator_document_country, required_operator_document_id: rod1.id, operator_id: operator, expire_date: Date.tomorrow)
    }
    let(:document2) {
      create(:operator_document_country, required_operator_document_id: rod2.id, operator_id: operator, expire_date: Date.tomorrow)
    }
    let(:documents) { [document1, document2] }
    let(:mail) { OperatorDocumentMailer.expiring_documents(operator, user, documents) }

    it "renders the headers" do
      expect(mail.subject).to eq("Expiring document(s) on the Open Timber Portal")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/The following document\(s\) from #{operator.name} is\/are expiring in 1 day/)
    end
  end

  describe "document_valid" do
    let(:document) { create(:operator_document_country, operator: operator, force_status: "doc_valid") }
    let(:mail) { OperatorDocumentMailer.document_valid(document, user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Open Timber Portal: new document published")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/The document #{document.name_with_fmu} has been validated and is now published/)
    end
  end

  describe "document_accepted_as_not_required" do
    let(:document) { create(:operator_document_country, operator: operator, force_status: "doc_not_required") }
    let(:mail) { OperatorDocumentMailer.document_accepted_as_not_required(document, user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Open Timber Portal: updated document")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/The document #{document.name_with_fmu} has been approved as not required/)
    end
  end

  describe "document_invalid" do
    let(:document) { create(:operator_document_country, operator: operator, force_status: "doc_invalid") }
    let(:mail) { OperatorDocumentMailer.document_invalid(document, user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Open Timber Portal: uploaded document was not validated")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/The following document was reviewed and needs to be revised/)
    end
  end
end

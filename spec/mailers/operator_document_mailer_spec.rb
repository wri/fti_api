require "rails_helper"

RSpec.describe OperatorDocumentMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe "expiring_documents" do
    let(:operator) { create(:operator) }

    let(:country) { create(:country) }
    let(:operator) { create(:operator, country_id: country.id) }
    let(:user) { create(:operator_user, operator: operator) }
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
end

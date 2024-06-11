require "rails_helper"

RSpec.describe GovDocumentMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  let(:country) { create(:country) }
  let(:user) { build(:government_user, country: country) }
  let(:document1) {
    build(:gov_document, country: country, expire_date: Date.tomorrow)
  }
  let(:document2) {
    build(:gov_document, country: country, expire_date: Date.tomorrow)
  }
  let(:documents) { [document1, document2] }

  describe "expiring_documents" do
    let(:mail) { GovDocumentMailer.expiring_documents(country, user, documents) }

    it "renders the headers" do
      expect(mail.subject).to eq("Expiring document(s) on the Open Timber Portal")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/The following document\(s\) from #{country.name} is\/are expiring in 1 day/)
    end
  end

  describe "expired_documents" do
    let(:mail) { GovDocumentMailer.expired_documents(country, user, documents) }

    it "renders the headers" do
      expect(mail.subject).to eq("You have 2 documents expired on the OTP")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/#{country.name} has 2 document\(s\) that are expired/)
    end
  end
end

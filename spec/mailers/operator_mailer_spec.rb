require 'rails_helper'

RSpec.describe OperatorMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe 'expiring_documents_notifications' do
    let(:operator) { create(:operator) }

    let(:country) { create(:country)}
    let(:operator) { create(:operator, country_id: country.id, email: 'test@mail.com')}
    let(:rod1) { create(:required_operator_document_country, country_id: country.id)}
    let(:rod2) { create(:required_operator_document_country, country_id: country.id)}
    let(:document1) {
      create(:operator_document_country, required_operator_document_id: rod1.id, operator_id: operator, expire_date: Date.tomorrow)
    }
    let(:document2) {
      create(:operator_document_country, required_operator_document_id: rod2.id, operator_id: operator, expire_date: Date.tomorrow)
    }
    let(:documents) { [document1, document2] }
    let(:mail) { OperatorMailer.expiring_documents_notifications(operator, documents) }

    it 'renders the headers' do
      expect(mail.subject).to eq('You have 2 documents expiring in 1 day')
      expect(mail.to).to eq([operator.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match(/#{operator.name} has 2 document\(s\) that are going to expire in 1 day/)
    end
  end

  describe 'quarterly_newsletter' do
    let(:operator) { create(:operator) }
    let(:mail) { OperatorMailer.quarterly_newsletter(operator) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Your OTP quarterly report. / Votre rapport trimestriel de OTP.')
      expect(mail.to).to eq(nil)
      expect(mail.bcc).to eq(operator.users.pluck(:email))
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Your current score is 0')
    end
  end
end

require 'rails_helper'

RSpec.describe SystemMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe 'user_created' do
    let(:user) { create(:user) }
    let(:mail) { SystemMailer.user_created(user) }

    it 'renders the headers' do
      expect(mail.subject).to eq('New USER created: ' + user.email)
      expect(mail.to).to eq([ENV['CONTACT_EMAIL']])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('A new USER has been created through the portal and required approval.')
    end
  end

  describe 'operator_created' do
    let(:operator) { create(:operator) }
    let(:mail) { SystemMailer.operator_created(operator) }

    it 'renders the headers' do
      expect(mail.subject).to eq('New OPERATOR created: ' + operator.name)
      expect(mail.to).to eq([ENV['CONTACT_EMAIL']])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('A new OPERATOR has been created through the portal and requires approval.')
    end
  end
end

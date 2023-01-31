require 'rails_helper'

RSpec.describe ObservationMailer, type: :mailer do
  let(:user) { create(:user) }

  describe 'notify_admin_published' do
    let(:observation) { create(:observation, responsible_admin: user, force_status: 'Published (modified)') }
    let(:mail) { ObservationMailer.notify_admin_published(observation) }

    it 'renders the headers' do
      expect(mail.subject).to eq('The operator responded to your requested changes')
      expect(mail.to).to eq([user.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include("#{observation.operator&.name} has responded to your requested changes.")
      expect(mail.body.encoded).to include("The status is now: #{observation.validation_status}")
    end
  end
end

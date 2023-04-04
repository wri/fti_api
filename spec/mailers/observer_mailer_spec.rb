require "rails_helper"

RSpec.describe ObserverMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "observation_status_changed" do
    let(:observer) { create(:observer) }
    let(:observation) { create(:observation, observers: [observer]) }
    let(:mail) { ObserverMailer.observation_status_changed(observer, user, observation) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("backend.mail_service.observer_status_changed.subject"))
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      # TODO create better specs after the mailer is refactored
      expect(mail.body.encoded).to match(/Your observation below \(#{observation.id}\) has a new status/)
    end
  end
end

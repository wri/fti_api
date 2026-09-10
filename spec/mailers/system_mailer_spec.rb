require "rails_helper"

RSpec.describe SystemMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe "user_created" do
    let(:user) { create(:user, country: create(:country)) }
    let(:mail) { SystemMailer.user_created(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("New account created")
      expect(mail.to).to eq([ENV["CONTACT_EMAIL"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("A new #{user.user_permission.user_role} user has been created through the portal and needs to be approved.")
    end
  end

  describe "operator_created" do
    let(:operator) { create(:operator) }
    let(:mail) { SystemMailer.operator_created(operator) }

    it "renders the headers" do
      expect(mail.subject).to eq("New operator created")
      expect(mail.to).to eq([ENV["CONTACT_EMAIL"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("A new operator has been created through the portal and needs to be approved.")
    end
  end

  describe "heartbeat" do
    let(:mail) { SystemMailer.heartbeat }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HEALTHCHECKS_ACCOUNT_ID").and_return("ping-key")
    end

    it "renders the headers" do
      expect(mail.subject).to eq("OTP API email heartbeat")
      expect(mail.to).to eq(["ping-key+test-email-heartbeat@hc-ping.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Email heartbeat sent at")
    end
  end
end

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  let(:user) { create(:user) }

  describe "user_acceptance" do
    let(:mail) { UserMailer.user_acceptance(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("New operator created")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Your user has been accepted on OTP. You can now use it to login.")
    end
  end

  describe "forgotten_password" do
    let(:mail) { UserMailer.forgotten_password(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Requested link to change your password")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Someone has requested a link to change your password. You can do this through the link below.")
    end
  end
end

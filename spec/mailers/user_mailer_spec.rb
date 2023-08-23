require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  let(:user) { create(:user) }

  describe "user_acceptance" do
    let(:mail) { UserMailer.user_acceptance(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Welcome to the Open Timber Portal!")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Your account has been activated and you can now login using the credentials that you selected.")
    end
  end

  describe "forgotten_password" do
    let(:mail) { UserMailer.forgotten_password(user) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("user_mailer.forgotten_password.subject"))
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(I18n.t("user_mailer.forgotten_password.message"))
    end
  end
end

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

  describe "inactive_account_warning" do
    let(:disable_date) { Date.new(2028, 1, 1) }
    let(:mail) { UserMailer.inactive_account_warning(user, disable_date) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("user_mailer.inactive_account_warning.subject", disable_date: I18n.l(disable_date)))
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(I18n.t("user_mailer.inactive_account_warning.message", disable_date: I18n.l(disable_date)))
    end
  end

  describe "account_deactivated_for_inactivity" do
    let(:mail) { UserMailer.account_deactivated_for_inactivity(user) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("user_mailer.account_deactivated_for_inactivity.subject"))
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(I18n.t("user_mailer.account_deactivated_for_inactivity.message"))
    end
  end
end

require "rails_helper"

RSpec.describe OperatorMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe "quarterly_newsletter" do
    let(:operator) { create(:operator) }
    let(:user) { create(:operator_user, operator: operator) }
    let(:mail) { OperatorMailer.quarterly_newsletter(operator, user) }

    it "renders the headers" do
      expect(mail.subject).to eq("#{operator.name} quarterly OTP report")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("#{operator.name} current score is 0")
    end
  end
end

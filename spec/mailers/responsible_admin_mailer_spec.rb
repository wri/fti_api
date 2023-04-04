require "rails_helper"

RSpec.describe ResponsibleAdminMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe "observation_ready_to_qc" do
    let(:observation) { create(:observation) }
    let(:mail) { ResponsibleAdminMailer.observation_ready_to_qc(observation) }

    it "renders the headers" do
      expect(mail.subject).to eq("Observation created with id #{observation.id} / Observation créée avec l'id #{observation.id}")
      expect(mail.to).to eq([ENV["RESPONSIBLE_EMAIL"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("The observation with the id #{observation.id} is ready for QC.")
    end
  end
end

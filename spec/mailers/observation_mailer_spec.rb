require "rails_helper"

RSpec.describe ObservationMailer, type: :mailer do
  let(:admin) { create(:admin) }
  let(:observer) { create(:observer, responsible_admin: admin) }
  let(:user) { create(:ngo, observer: observer) }
  let(:observation) { create(:observation, observers: [user.observer], modified_user: user) }

  describe "admin_observation_published_not_modified" do
    let(:mail) { ObservationMailer.admin_observation_published_not_modified(observation, admin) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "#{observation.modified_user.observer.name} published observation [ID #{observation.id}] without modifications"
      )
      expect(mail.to).to eq([admin.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "#{observation.modified_user.observer.name} has decided to publish observation [ID #{observation.id}] without making any edits."
      )
    end
  end

  describe "admin_observation_ready_for_qc" do
    let(:mail) { ObservationMailer.admin_observation_ready_for_qc(observation, admin) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "Observation [ID #{observation.id}] is ready for quality control"
      )
      expect(mail.to).to eq([admin.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "#{observation.modified_user.observer.name} has been submitted an observation through the portal that is ready be reviewed."
      )
    end
  end

  describe "observation_created" do
    let(:mail) { ObservationMailer.observation_created(observation, user) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "Observation [ID #{observation.id}] was successfully created"
      )
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "The observation will not be reviewed by the OTP team"
      )
    end
  end

  describe "observation_submitted_for_qc" do
    let(:mail) { ObservationMailer.observation_submitted_for_qc(observation, user) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "Observation [ID #{observation.id}] was successfully submitted for quality control"
      )
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "The following observation was successfully submitted for quality control."
      )
    end
  end

  describe "observation_needs_revision" do
    let(:mail) { ObservationMailer.observation_needs_revision(observation, user) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "Observation [ID #{observation.id}] needs revision before it can be published"
      )
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "The following observation needs to be reviewed before it can be published."
      )
    end
  end

  describe "observation_ready_for_publication" do
    let(:mail) { ObservationMailer.observation_ready_for_publication(observation, user) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "Observation [ID #{observation.id}] is ready for publication"
      )
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "Please click on the following link and publish the observation"
      )
    end
  end

  describe "observation_published" do
    let(:mail) { ObservationMailer.observation_published(observation, user) }

    it "renders the headers" do
      expect(mail.subject).to eq(
        "Observation [ID #{observation.id}] is now published"
      )
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(
        "You can view it in the list of observations on the platform"
      )
    end
  end
end

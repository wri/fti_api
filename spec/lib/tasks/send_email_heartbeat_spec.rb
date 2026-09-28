require "rails_helper"

Rails.application.load_tasks if Rake::Task.tasks.empty?

describe "send_email_heartbeat" do
  after(:each) do
    Rake::Task["scheduler:send_email_heartbeat"].reenable
  end

  subject { Rake::Task["scheduler:send_email_heartbeat"].invoke }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("HEALTHCHECKS_ACCOUNT_ID").and_return(account_id)
  end

  context "when the healthchecks account id is set" do
    let(:account_id) { "ping-key" }

    it "enqueues the heartbeat email" do
      expect { subject }.to have_enqueued_mail(SystemMailer, :heartbeat)
    end
  end

  context "when the healthchecks account id is not set" do
    let(:account_id) { nil }

    it "raises without enqueuing anything" do
      expect {
        expect { subject }.to raise_error("HEALTHCHECKS_ACCOUNT_ID is not set")
      }.not_to have_enqueued_mail(SystemMailer, :heartbeat)
    end
  end
end

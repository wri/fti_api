require "rails_helper"

Rails.application.load_tasks if Rake::Task.tasks.empty?

describe "send_quarterly_newsletters" do
  after(:each) do
    Rake::Task["scheduler:send_quarterly_newsletters"].reenable
    ActionMailer::Base.deliveries.clear
  end

  let(:country) { create :country }
  let(:required_operator_document) { create :required_operator_document_country, country: country }
  let(:holding) { create :holding }
  let!(:operator) { create :operator, fa_id: "fa_id", country: country }
  let!(:operator2) { create :operator, fa_id: "fa_id2", country: country, holding: holding }
  let!(:operator3) { create :operator, fa_id: "fa_id3", country: country, holding: holding }
  let!(:user1) { create :operator_user, country: country, operator: operator }
  let!(:user2) { create :operator_user, country: country, operator: operator, is_active: false }
  let!(:user3) { create :operator_user, country: country, operator: operator2 }
  let!(:user4) { create :holding_user, country: country, holding: holding } # this one should get 2 emails

  subject { Rake::Task["scheduler:send_quarterly_newsletters"].invoke }

  it "sends newsletter to all active eligible users" do
    expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(4)
      .and change { ActionMailer::Base.deliveries.flat_map(&:to).sort }.to([user1.email, user3.email, user4.email, user4.email].sort)
  end
end

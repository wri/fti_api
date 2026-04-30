require "rails_helper"

Rails.application.load_tasks if Rake::Task.tasks.empty?

describe "deactivate_inactive_users" do
  include ActiveSupport::Testing::TimeHelpers

  after(:each) do
    Rake::Task["scheduler:deactivate_inactive_users"].reenable
    ActionMailer::Base.deliveries.clear
  end

  subject(:run_task) { Rake::Task["scheduler:deactivate_inactive_users"].invoke }

  around do |example|
    travel_to(Time.zone.parse("2026-04-30 10:00:00")) { example.run }
  end

  it "sends one warning email at 18 months inactivity" do
    warned_user = create(:operator_user, last_sign_in_at: 18.months.ago)
    create(:operator_user, last_sign_in_at: 19.months.ago)

    expect { run_task }.to change { ActionMailer::Base.deliveries.count }.by(1)

    mail = ActionMailer::Base.deliveries.first
    expect(mail.to).to eq([warned_user.email])
    expect(mail.body.encoded).to include(I18n.l(warned_user.last_sign_in_at.to_date + 2.years))
  end

  it "deactivates users inactive for 2 years or more" do
    old_user = create(:operator_user, is_active: true, last_sign_in_at: 2.years.ago - 1.day, deactivated_at: nil)
    active_user = create(:operator_user, is_active: true, last_sign_in_at: 1.year.ago)

    expect { run_task }
      .to change { old_user.reload.is_active }.from(true).to(false)
      .and change { active_user.reload.is_active }.by(0)

    expect(old_user.reload.deactivated_at).to be_present
    expect(ActionMailer::Base.deliveries.last.to).to eq([old_user.email])
    expect(ActionMailer::Base.deliveries.last.subject).to eq(I18n.t("user_mailer.account_deactivated_for_inactivity.subject"))
  end

  it "uses created_at when user has never logged in" do
    never_logged_user = create(:operator_user, last_sign_in_at: nil, created_at: 18.months.ago)

    expect { run_task }.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(ActionMailer::Base.deliveries.first.to).to eq([never_logged_user.email])
  end
end

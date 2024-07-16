require "dotenv"
Dotenv.load

account_id = ENV["HEALTHCHECKS_ACCOUNT_ID"]
env = ENV["RAILS_ENV"]

abort "HEALTHCHECKS_ACCOUNT_ID is not set" unless account_id

check_in = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/#{account_id}/#{env}-:check_in"
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task --silent :output && #{check_in}"

every 1.day, at: "1 am" do
  rake "scheduler:calculate_scores", check_in: "calculate"
  rake "scheduler:expire", check_in: "expire-documents"
  rake "scheduler:set_active_fmu_operator", check_in: "update-fmus"
  rake "scheduler:create_notifications", check_in: "create-notifications"
  rake "scheduler:generate_documents_stats", check_in: "generate-documents-stats"
  rake "scheduler:generate_observation_reports_stats", check_in: "generate-observation-reports-stats"
  rake "observations:hide", check_in: "hide-old-observations"
end

every 1.day, at: "6 am" do
  rake "notify_expiration:send", check_in: "notify-about-expired-documents"
end

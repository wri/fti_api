require "dotenv"
Dotenv.load

account_id = ENV["HEALTHCHECKS_ACCOUNT_ID"]
env = ENV["RAILS_ENV"]

raise "HEALTHCHECKS_ACCOUNT_ID is not set" unless account_id

unless ENV["SKIP_CRON"] == "true"
  nvm_exec = "NODE_VERSION=default ~/.nvm/nvm-exec"
  check_in = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/#{account_id}/#{env}-:check_in"
  job_type :rake, "cd :path && :environment_variable=:environment #{nvm_exec} bundle exec rake :task --silent :output && #{check_in}"
  set :output, "#{path}/log/cron.log"
  every 1.day, at: "1 am" do
    rake "scheduler:expire", check_in: "expire-documents"
    rake "scheduler:set_active_fmu_operator", check_in: "update-fmus"
    rake "scheduler:generate_documents_stats", check_in: "generate-documents-stats"
    rake "scheduler:generate_observation_reports_stats", check_in: "generate-observation-reports-stats"
  end

  every 1.hour do
    rake "observations:hide", check_in: "hide-old-observations"
    rake "scheduler:calculate_scores", check_in: "calculate"
    rake "scheduler:create_notifications", check_in: "create-notifications"
  end

  every 1.day, at: "6 am" do
    rake "notify_expiration:send", check_in: "notify-about-expired-documents"
  end

  # send every quarter, on the first day of the month at 8:00
  every "0 8 1 */3 *" do
    rake "scheduler:send_quarterly_newsletters", check_in: "quarterly-newsletter"
  end
end

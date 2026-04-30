require "dotenv"
Dotenv.load

account_id = ENV["HEALTHCHECKS_ACCOUNT_ID"]
env = ENV["RAILS_ENV"]

raise "HEALTHCHECKS_ACCOUNT_ID is not set" unless account_id

unless ENV["SKIP_CRON"] == "true"
  nvm_exec = "NODE_VERSION=default ~/.nvm/nvm-exec"
  check_in = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/#{account_id}/#{env}-:check_in"
  job_type :rake, "cd :path && :environment_variable=:environment #{nvm_exec} bundle exec rake :task --silent :output"
  job_type :rake_with_check, "cd :path && :environment_variable=:environment #{nvm_exec} bundle exec rake :task --silent :output && #{check_in}"
  set :output, "#{path}/log/cron.log"
  every 1.day, at: "1 am" do
    rake_with_check "scheduler:expire", check_in: "expire-documents"
    rake_with_check "scheduler:set_active_fmu_operator", check_in: "update-fmus"
    rake_with_check "scheduler:generate_documents_stats", check_in: "generate-documents-stats"
    rake_with_check "scheduler:generate_observation_reports_stats", check_in: "generate-observation-reports-stats"
    rake "scheduler:deactivate_inactive_users", check_in: "deactivate-inactive-users"
    rake "scheduler:clean_cache"
  end

  every 1.hour do
    rake_with_check "observations:hide", check_in: "hide-old-observations"
    rake_with_check "scheduler:calculate_scores", check_in: "calculate"
    rake_with_check "scheduler:create_notifications", check_in: "create-notifications"
  end

  every 1.day, at: "6 am" do
    rake_with_check "notify_expiration:send", check_in: "notify-about-expired-documents"
  end

  # send every quarter, on the first day of the month at 8:00
  every "0 8 1 */3 *" do
    rake_with_check "scheduler:send_quarterly_newsletters", check_in: "quarterly-newsletter"
  end
end

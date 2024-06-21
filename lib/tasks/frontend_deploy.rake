require "open3"
namespace :deploy do
  task tools: :environment do
    Rails.logger.warn ":::: Going to redeploy the IM Backoffice :::::"
    command = if Rails.env.staging?
      "$HOME/otp-observations-tool-staging/script/deploy staging"
    else
      "$HOME/otp-observations-tool/script/deploy"
    end
    begin
      unset_app_env = Dotenv.parse.transform_values { nil } # Unset all the env variables to avoid conflicts
      stdout, stderr, status = Open3.capture3(unset_app_env, command)
      raise stderr unless status.success?
    rescue => e
      Sentry.capture_exception e
      Rails.logger.error e.inspect
      raise
    ensure
      Rails.logger.debug stdout
      Rails.logger.debug stderr
      Rails.logger.debug status
    end
    Rails.logger.warn ":::: Finished redeploying the observations tool :::::"
  end

  desc "Deploys the portal"
  task portal: :environment do
    Rails.logger.warn ":::: Going to redeploy the portal :::::"
    command = if Rails.env.staging?
      "$HOME/otp-portal-staging/script/deploy staging"
    else
      "$HOME/otp-portal/script/deploy"
    end
    begin
      unset_app_env = Dotenv.parse.transform_values { nil } # Unset all the env variables to avoid conflicts
      stdout, stderr, status = Open3.capture3(unset_app_env, command)
      raise stderr unless status.success?
    rescue => e
      Sentry.capture_exception e
      Rails.logger.error e.inspect
      raise
    ensure
      Rails.logger.debug stdout
      Rails.logger.debug stderr
      Rails.logger.debug status
    end
    Rails.logger.warn ":::: Finished redeploying the portal :::::"
  end
end

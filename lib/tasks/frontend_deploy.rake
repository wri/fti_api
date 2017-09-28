require 'open3'
namespace :deploy do

  task tools: :environment do
    Rails.logger.warn ':::: Going to redeploy the IM Backoffice :::::'
    command =  'cd ../../otp-observations-tool; npm run prod-build'
    begin
      stdout, stderr, status = Open3.capture3(command)
    rescue Exception => e
      Rails.logger.error e.inspect
    end
    Rails.logger.debug stdout
    Rails.logger.debug stderr
    Rails.logger.debug status
    Rails.logger.warn ':::: Finished redeploying the observations tool :::::'
  end

  desc 'Deploys the portal'
  task portal: :environment do
    Rails.logger.warn ':::: Going to redeploy the portal :::::'
    command =  'cd ../../otp-portal; npm run transifex:pull; npm run build'
    begin
      stdout, stderr, status = Open3.capture3(command)
    rescue Exception => e
      Rails.logger.error e.inspect
    end
    Rails.logger.debug stdout
    Rails.logger.debug stderr
    Rails.logger.debug status
    Rails.logger.warn ':::: Finished redeploying the portal :::::'
  end
end
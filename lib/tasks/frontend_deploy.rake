require 'open3'
namespace :deploy do

  task tools: :environment do

  end

  task portal: :environment do
    Rails.logger.warn ':::: Going to redeploy the portal :::::'
    command =  '../../otp-portal/npm run build'
    stdout, stderr, status = Open3.capture3(command)
    Rails.logger.debug stdout
    Rails.logger.debug stderr
    Rails.logger.debug status
    Rails.logger.warn ':::: Finished redeploying the portal :::::'
  end
end
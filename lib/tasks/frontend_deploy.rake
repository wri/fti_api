require 'open3'
namespace :deploy do

  task tools: :environment do

  end

  task portal: :environment do
    Rails.logger.warn ':::: Going to redeploy the portal :::::'
    command =  'cd ../../otp-portal; npm run build'
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
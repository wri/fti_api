require 'open3'
namespace :deploy do

  task tools: :environment do
    Rails.logger.warn ':::: Going to redeploy the IM Backoffice :::::'
    # Changed the PATH. The former one didn't have the node folders
    command =  'export PATH="/home/ubuntu/.rvm/gems/ruby-2.4.1/bin:/home/ubuntu/.rvm/gems/ruby-2.4.1@global/bin:/home/ubuntu/.rvm/rubies/ruby-2.4.1/bin:/home/ubuntu/bin:/home/ubuntu/.local/bin:/home/ubuntu/.nvm/versions/node/v10.9.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/ubuntu/.rvm/bin"; cd ../../otp-observations-tool; npm install; npm run transifex:pull; npm run prod-build'
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
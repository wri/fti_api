namespace :deploy do

  task tools: :environment do

  end

  task portal: :environment do
    Rails.logger.warn ':::: Going to redeploy the portal'
    sh 'cd ../../otp-portal'
    sh 'npm run build'
  end
end
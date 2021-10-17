namespace :notify_expiration do
  desc 'Send notification for expiring documents'
  task send: :environment do
    ExpirationNotifierService.new.call
  end
end

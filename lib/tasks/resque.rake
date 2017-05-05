require 'resque/tasks'

# RAILS_ENV=staging bundle exec rake resque:work BACKGROUND=2
namespace :resque do
  task setup: :environment do
    ENV['QUEUE'] = 'mailer'
    Rake::Task['resque:work'].invoke
  end
end

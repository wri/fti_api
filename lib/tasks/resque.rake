require 'resque/tasks'

namespace :resque do
  task setup: :environment do
    ENV['QUEUE'] = 'mailer'
    Rake::Task['resque:work'].invoke
  end
end

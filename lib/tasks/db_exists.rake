namespace :db do
  desc 'Check if db exists'
  task exists: :environment do
    begin
      ActiveRecord::Base.connection
    rescue
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      puts '* Loading Data... *'
      Rake::Task['db:seed'].invoke unless Rails.env.test?
      puts '* Data successfully loaded. *'
    else
      Rake::Task['db:migrate'].invoke
      puts '* Loading Data... *'
      Rake::Task['db:seed'].invoke unless Rails.env.test?
      puts '* Data successfully loaded. *'
    end

    log_directory_name = 'log'
    FileUtils.mkdir(log_directory_name) unless File.exists?(log_directory_name)

    pids_directory_name = 'tmp/pids'
    FileUtils.mkdir_p(pids_directory_name) unless File.exists?(pids_directory_name)
  end

  desc 'Rebuilds and imports the database'
  task :destroy_and_rebuild do
    puts 'Are you sure you want to destroy and rebuild the database? (type "yes" to continue)'
    input = STDIN.gets.chomp
    return unless input == 'yes'

    puts ':::: Going to backup the database'
    sh "pg_dump fti_api_staging > #{DateTime.now.to_date}.dump"

    puts ':::: Stopping nginx'
    sh 'sudo service nginx stop'

    puts ':::: Creating and importing the database'
    sh 'RAILS_ENV=staging bundle exec rails db:drop db:schema:load db:create db:seed'

    puts ':::: Calculating documents percentages'
    sh 'RAILS_ENV=staging bundle exec rails documents:percentages'

    puts ':::: Calculating observation scores'
    sh 'RAILS_ENV=staging bundle exec rails observation_scores:calculate'

    puts 'Restart nginx'
    sh 'sudo service nginx start'

    puts 'Creating the permissions for the users'
    Rake::Task['permissions:update'].invoke

    puts 'Generating API Keys for all users'
    User.find_each {|x| x.regenerate_api_key}

  end
end

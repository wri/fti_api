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
end

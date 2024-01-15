namespace :db do
  desc "Download database from server - Params: SERVER=production(default)|staging, SMALL (if present we ignore versions table data))"
  task :download do # rubocop:disable Rails/RakeEnvironment
    server = ENV.fetch("SERVER", "production")
    params = ENV["SMALL"] ? "DB_IGNORE_DATA_TABLES=versions" : ""

    sh "mkdir -p ./db/dumps/#{server}"
    puts "Downloading database from #{server}"
    sh "cap #{server} db:download #{params}"
  end

  desc "Load dump into local database - Params: FILE=path_to_dump (if not specified, latest dump will be used, SERVER, FORCE"
  task :restore_from_file do # rubocop:disable Rails/RakeEnvironment
    abort "Loading dump only in dev environment, or when using FORCE env" unless Rails.env.development? || ENV["FORCE"]

    dump_file = ENV["FILE"]
    unless dump_file
      server = ENV.fetch("SERVER", "production")

      puts "No file specified, using latest #{server} dump (use SERVER env to change server)"

      dump_dir = Rails.root.join("db", "dumps", server)
      dump_file = Dir["#{dump_dir}/*"].max_by { |f| File.mtime(f) }
    end
    abort "No dump file found" unless dump_file

    compressed = dump_file.end_with?(".gz")
    if compressed
      puts "Decompressing dump"
      sh "gzip -dk #{dump_file}"
      dump_file = dump_file.gsub(".gz", "")
    end
    sh "docker-compose restart db" # just in case if load task cannot drop the database
    sh "cap development db:local:load DUMP_FILE=#{dump_file}"
    sh "rm #{dump_file}" if compressed
    Rake::Task["db:prepare_for_dev"].invoke
    Rake::Task["db:environment:set"].invoke
  end

  desc "Restore database from server - Params: SERVER=production(default)|staging, SMALL (if present we ignore versions table data)"
  task :restore_from_server do # rubocop:disable Rails/RakeEnvironment
    abort "Loading dump only in dev environment, or when using FORCE env" unless Rails.env.development? || ENV["FORCE"]

    params = ENV["SMALL"] ? "DB_IGNORE_DATA_TABLES=versions" : ""
    server = ENV.fetch("SERVER", "production")

    sh "docker-compose restart db" # just in case if load task cannot drop the database
    sh "cap #{server} db:pull #{params}"
    Rake::Task["db:prepare_for_dev"].invoke
    Rake::Task["db:environment:set"].invoke
  end

  desc "Prepare database for dev enviroment"
  task prepare_for_dev: :environment do
    ActiveRecord::Base.connection.reconnect! # make sure connection is open
    puts "Changing all users passwords to secret"
    User.update_all(encrypted_password: User.new(password: "secret").encrypted_password)
  end
end

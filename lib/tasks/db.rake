namespace :db do
  desc "Download database from server - Params: SERVER=production(default)|staging, SMALL (if present we ignore versions table data))"
  task download: :environment do
    server = ENV.fetch("SERVER", "production")
    params = ENV["SMALL"] ? "DB_IGNORE_DATA_TABLES=versions" : ""

    sh "mkdir -p ./db/dumps"
    puts "Downloading database from #{server}"
    sh "cap #{server} db:download #{params}"
  end

  desc "Load dump into local database - Params: FILE=path_to_dump (if not specified, latest dump will be used, FORCE"
  task restore_from_file: :environment do
    abort "Loading dump only in dev environment, or when using FORCE env" unless Rails.env.development? || ENV["FORCE"]

    dump_dir = Rails.root.join("db", "dumps")
    dump_file = ENV["FILE"]
    unless dump_file
      puts "No file specified, using latest dump"
      dump_file = Dir["#{dump_dir}/*"].max_by { |f| File.mtime(f) }
    end
    abort "No dump file found" unless dump_file

    compressed = dump_file.end_with?(".gz")
    if compressed
      puts "Decompressing dump"
      sh "gzip -dk #{dump_file}"
      dump_file = dump_file.gsub(".gz", "")
    end
    sh "cap development db:local:load DUMP_FILE=#{dump_file}"
    sh "rm #{dump_file}" if compressed
    Rake::Task["db:prepare_for_dev"].invoke
  end

  desc "Restore database from server - Params: SERVER=production(default)|staging, SMALL (if present we ignore versions table data)"
  task restore_from_server: :environment do
    abort "Loading dump only in dev environment, or when using FORCE env" unless Rails.env.development? || ENV["FORCE"]

    params = ENV["SMALL"] ? "DB_IGNORE_DATA_TABLES=versions" : ""
    server = ENV.fetch("SERVER", "production")

    sh "cap #{server} db:pull #{params}"
    Rake::Task["db:prepare_for_dev"].invoke
  end

  desc "Prepare database for dev enviroment"
  task prepare_for_dev: :environment do
    ActiveRecord::Base.connection.reconnect! # make sure connection is open
    puts "Changing all users passwords to secret"
    User.update_all(encrypted_password: User.new(password: "secret").encrypted_password)
  end
end

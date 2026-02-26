# require "dotenv/tasks"

def human_file_size(path)
  size = File.size(path).to_f
  %w[B KB MB GB TB].each_with_index do |unit, i|
    return format("%.1f %s", size, unit) if size < 1024 || i == 4
    size /= 1024.0
  end
end

def db_dump_files_sorted(dumps_root, server = "all")
  servers = (server == "all") ? Dir["#{dumps_root}/*/"].map { |d| File.basename(d) } : [server]
  servers.flat_map { |srv| Dir["#{dumps_root}/#{srv}/*"].map { |f| [srv, f] } }
    .sort_by { |_, f| File.mtime(f) }.reverse
end

namespace :db do
  desc "Download database from server - Params: SERVER=production(default)|staging, SMALL (if present we ignore versions table data))"
  task :download do # rubocop:disable Rails/RakeEnvironment
    server = ENV.fetch("SERVER", "production")
    params = ENV["SMALL"] ? "DB_IGNORE_DATA_TABLES=versions" : ""

    sh "mkdir -p ./db/dumps/#{server}"
    puts "Downloading database from #{server}"
    sh "cap #{server} db:download #{params}"
  end

  desc "Load dump into local database - Params: FILE=path_to_dump, INDEX=n (from dump_list), SERVER, FORCE"
  task :restore_from_file do # rubocop:disable Rails/RakeEnvironment
    abort "Loading dump only in dev environment, or when using FORCE env" unless Rails.env.development? || ENV["FORCE"]

    dumps_root = Rails.root.join("db", "dumps")
    dump_file = ENV["FILE"]

    if !dump_file && ENV["INDEX"]
      index = ENV["INDEX"].to_i
      abort "INDEX must be a positive integer" unless index > 0
      server = ENV.fetch("SERVER", "all")
      files = db_dump_files_sorted(dumps_root, server)
      _srv, dump_file = files[index - 1]
      abort "No dump file at index #{index} (run rake db:dump_list to see available files)" unless dump_file
    end

    unless dump_file
      server = ENV.fetch("SERVER", "production")

      puts "No file specified, using latest #{server} dump (use SERVER env to change server)"

      dump_dir = dumps_root.join(server)
      dump_file = Dir["#{dump_dir}/*"].max_by { |f| File.mtime(f) }
    end
    abort "No dump file found" unless dump_file

    print "Restore database from #{dump_file}? [y/N] "
    abort "Aborted" unless $stdin.gets.to_s.strip.casecmp("y").zero?

    compressed = dump_file.end_with?(".gz")
    if compressed
      puts "Decompressing dump"
      sh "gzip -dk #{dump_file}"
      dump_file = dump_file.delete_suffix(".gz")
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

  desc "List all available dump files - Params: SERVER=production|staging|all(default)"
  task :dump_list do # rubocop:disable Rails/RakeEnvironment
    server = ENV.fetch("SERVER", "all")
    dumps_root = Rails.root.join("db", "dumps")
    files = db_dump_files_sorted(dumps_root, server)

    if files.empty?
      puts "No dump files found"
      next
    end

    file_col = files.map { |_, f| File.basename(f).length }.max
    puts "%-5s  %-12s  %-#{file_col}s  %-10s  %s" % ["INDEX", "SERVER", "FILE", "SIZE", "DATE MODIFIED"]
    puts "-" * (5 + 2 + 12 + 2 + file_col + 2 + 10 + 2 + 19)
    files.each_with_index do |(srv, f), i|
      mtime = File.mtime(f).strftime("%Y-%m-%d %H:%M:%S")
      puts "%-5s  %-12s  %-#{file_col}s  %-10s  %s" % [i + 1, srv, File.basename(f), human_file_size(f), mtime]
    end
  end

  desc "Prepare database for dev environment"
  task prepare_for_dev: :environment do
    ActiveRecord::Base.connection.reconnect! # make sure connection is open
    puts "Changing all users passwords to Supersecret1"
    User.update_all(encrypted_password: User.new(password: "Supersecret1").encrypted_password)
  end

  desc "Import Maxmind GeoIP database (requires MAXMIND_LICENSE_KEY env variable)"
  task import_maxmind_db: :environment do
    edition_id = "GeoLite2-City"
    db_path = Rails.root.join("db", "#{edition_id}.mmdb")
    tmp_file = Rails.root.join("tmp", "tmp.mmdb.tar.gz")

    # check if db_path file exists and is not yet 30 days old
    if !ENV["FORCE"] && File.exist?(db_path) && File.mtime(db_path) > 30.days.ago
      puts "Maxmind DB already exists and is less than 30 days old, skipping download"
      next
    end

    account_id = ENV["MAXMIND_ACCOUNT_ID"]
    key = ENV["MAXMIND_LICENSE_KEY"]
    url = "https://download.maxmind.com/geoip/databases/#{edition_id}/download?suffix=tar.gz"

    abort "NO MAXMIND LICENSE KEY" unless key.present?

    puts "DOWNLOADING MAXMIND DB..."
    abort "Maxmind download error" unless system "wget -q -c --tries=3 --user=#{account_id} --password=#{key} '#{url}' -O #{tmp_file}"
    abort "Maxmind unzip error" unless system "cd tmp && tar -xvf #{tmp_file} --wildcards --strip-components 1 '*.mmdb' && mv #{edition_id}.mmdb #{db_path}"

    system "rm #{tmp_file}"

    puts "MAXMIND DB DOWNLOADED!"
  end

  # https://github.com/maxmind/MaxMind-DB/blob/main/test-data
  desc "Import Maxmind GeoIP test database (for test and dev env)"
  task import_maxmind_test_db: :environment do
    edition_id = "GeoLite2-City-Test"
    db_path = Rails.root.join("db", "#{edition_id}.mmdb")
    url = "https://github.com/maxmind/MaxMind-DB/raw/refs/heads/main/test-data/#{edition_id}.mmdb"

    puts "DOWNLOADING MAXMIND CITY TEST DB..."
    abort "Maxmind download error" unless system "wget -q -c --tries=3 '#{url}' -O #{db_path}"

    puts "MAXMIND CITY TEST DB DOWNLOADED!"
  end
end

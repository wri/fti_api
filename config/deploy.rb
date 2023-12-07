# frozen_string_literal: true

# config valid only for current version of Capistrano
lock "~> 3.12"

set :application, "OtpAPI"
set :repo_url, "git@github.com:Vizzuality/fti_api.git"

ruby_version = File.read(".ruby-version").strip

set :default_env, {
  "PATH" => "/home/ubuntu/.rvm/gems/ruby-#{ruby_version}/bin:/home/ubuntu/.rvm/bin:$PATH",
  "RUBY_VERSION" => "ruby-#{ruby_version}",
  "GEM_HOME" => "/home/ubuntu/.rvm/gems/ruby-#{ruby_version}",
  "GEM_PATH" => "/home/ubuntu/.rvm/gems/ruby-#{ruby_version}",
  "BUNDLE_PATH" => "/home/ubuntu/.rvm/gems/ruby-#{ruby_version}"
}

set :passenger_restart_with_touch, true

set :rvm_type, :user
set :rvm_ruby_version, ruby_version
set :rvm_roles, [:app, :web, :db]

set :keep_releases, 5

set :linked_files, %w[.env]
set :linked_dirs, %w[log db/dumps tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads private]

append :rvm_map_bins, "rvmsudo", "rails"

# db tasks config
set :db_local_clean, true
set :db_remote_clean, true
set :db_ignore_tables, []
set :db_ignore_data_tables, (ENV["DB_IGNORE_DATA_TABLES"] || "").split(",")
set :db_dump_dir, -> { File.join(current_path, "db") }
set :disallow_pushing, true # Do not change this
set :compressor, :gzip
# end of db tasks config

namespace :db do
  task :download do
    on roles(:db) do
      remote_db = Database::Remote.new(self)
      $stdout.puts "Downloading remote dump..."
      begin
        remote_db.dump
        remote_db.download "db/dumps/#{remote_db.output_file}"
      rescue e
        $stdout.puts "E[#{e.class}]: #{e.message}"
      ensure
        remote_db.clean_dump_if_needed
      end
    end
  end

  namespace :local do
    task :load do
      run_locally do
        dump_file = ENV["DUMP_FILE"]

        raise "You must specify a dump file using the DUMP_FILE environment variable" if dump_file.nil?
        raise "File #{dump_file} does not exist" unless File.exist?(dump_file)

        local_db = Database::Local.new(self)
        local_db.load(dump_file, false)
      end
    end
  end
end

namespace :sidekiq do
  task :quiet do
    on roles(:app) do
      $stdout.puts capture("pgrep -f 'sidekiq' | xargs kill -TSTP")
    end
  end
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end
end

namespace :deploy do
  after :starting, "sidekiq:quiet"
  after :finishing, "deploy:cleanup"
  after :reverted, "sidekiq:restart"
  after :published, "sidekiq:restart"
end

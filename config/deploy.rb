# frozen_string_literal: true

# config valid only for current version of Capistrano
lock "~> 3.12"

set :application, "otp_api"
set :repo_url, "git@github.com:wri/fti_api.git"

ruby_version = File.read(".ruby-version").strip
rvm_path = "/usr/share/rvm"
user = ENV["SSH_USER"]

set :puma_threads, [4, 16]
set :puma_workers, 0
set :puma_service_unit_name, "puma"
set :puma_service_unit_env_vars, %w[RAILS_ENV=staging]

set :systemctl_user, :system

set :rvm_type, :user
set :rvm_ruby_version, ruby_version
set :rvm_custom_path, rvm_path
set :rvm_roles, [:app, :web, :db]

set :nvm_node, "default"
set :nvm_map_bins, %w[node npm yarn rake rails]

set :keep_releases, 5

set :linked_files, %w[.env]
set :linked_dirs, %w[log db/dumps tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads uploads private]

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
      dump_dir = ENV.fetch("DUMP_DIR", "db/dumps/#{fetch(:stage)}")
      remote_db = Database::Remote.new(self)
      $stdout.puts "Downloading remote dump..."
      begin
        remote_db.dump
        remote_db.download "#{dump_dir}/#{remote_db.output_file}"
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

  before :download, "nvm:map_bins"
end

task "deploy:db:load" do
  on primary :db do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, "db:version"
      rescue
        # only create if db does not exist
        execute :rake, "db:create"
        execute :rake, "db:schema:load"
      end
    end
  end
end

namespace :sidekiq do
  task :quiet do
    on roles(:app) do
      $stdout.puts capture("pgrep -f 'sidekiq' | xargs sudo kill -TSTP")
    end
  end
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end
end

namespace :nvm do
  task :map_bins do
    on roles(:all) do
      SSHKit.config.default_env[:node_version] = fetch(:nvm_node)
      nvm_prefix = "/home/#{user}/.nvm/nvm-exec"
      fetch(:nvm_map_bins).each do |command|
        SSHKit.config.command_map.prefix[command.to_sym].unshift(nvm_prefix)
      end
      execute :node, "-v"
    end
  end
end

# TODO: not sure why sometimes there are some logs or other temp files that belongs to root not a app user
task "deploy:fix_permissions" do
  on roles(:all) do |host|
    execute :sudo, :chown, "-R", "#{host.user}:#{host.user}", "#{fetch(:deploy_to)}/releases"
  end
end

namespace :deploy do
  before :check, "nvm:map_bins"
  before :migrate, "deploy:db:load"
  before :cleanup, "deploy:fix_permissions"
  after :starting, "sidekiq:quiet"
  after :reverted, "sidekiq:restart"
  after :published, "sidekiq:restart"
end

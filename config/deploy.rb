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
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads private]

set :rvm_map_bins, fetch(:rvm_map_bins, []).push("rvmsudo")

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

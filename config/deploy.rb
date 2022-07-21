# frozen_string_literal: true

# config valid only for current version of Capistrano
lock '3.12.0'

set :application, 'OtpAPI'
set :repo_url, 'git@github.com:Vizzuality/fti_api.git'

set :default_env, {
  'PATH' => "/home/ubuntu/.rvm/gems/ruby-2.4.6/bin:/home/ubuntu/.rvm/bin:$PATH",
  'RUBY_VERSION' => 'ruby-2.4.6',
  'GEM_HOME' => '/home/ubuntu/.rvm/gems/ruby-2.4.6',
  'GEM_PATH' => '/home/ubuntu/.rvm/gems/ruby-2.4.6',
  'BUNDLE_PATH' => '/home/ubuntu/.rvm/gems/ruby-2.4.6'
}

set :passenger_restart_with_touch, true

set :rvm_type, :user
set :rvm_ruby_version, '2.4.6'
set :rvm_roles, [:app, :web, :db]

set :keep_releases, 5

set :linked_files, %w{.env}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads private}

set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rvmsudo')

namespace :deploy do
  after :finishing, 'deploy:cleanup'
end

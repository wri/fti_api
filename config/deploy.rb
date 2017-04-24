# frozen_string_literal: true

# config valid only for current version of Capistrano
lock '3.8.1'

set :application, 'OtpAPI'
set :repo_url, 'git@github.com:Vizzuality/fti_api.git'

set :passenger_restart_with_touch, true

set :rvm_type, :auto
set :rvm_ruby_version, '2.4.0'
set :rvm_roles, [:app, :web, :db]

set :keep_releases, 5

set :linked_files, %w{.env}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}

set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rvmsudo')

namespace :deploy do
  after :finishing, 'deploy:cleanup'
  after 'deploy:publishing', 'deploy:symlink:linked_files', 'deploy:symlink:linked_dirs', 'deploy:restart'
end

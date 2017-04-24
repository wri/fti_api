# frozen_string_literal: true

# config valid only for current version of Capistrano
lock '3.8.1'

set :application, 'OtpAPI'
set :repo_url, 'git@github.com:Vizzuality/fti_api.git'

set :default_env, {
  'PATH' => "/home/ubuntu/.rvm/gems/ruby-2.4.0/bin:/home/ubuntu/.rvm/bin:$PATH",
  'RUBY_VERSION' => 'ruby-2.4.0',
  'GEM_HOME'     => '/home/ubuntu/.rvm/gems/ruby-2.4.0',
  'GEM_PATH'     => '/home/ubuntu/.rvm/gems/ruby-2.4.0',
  'BUNDLE_PATH'  => '/home/ubuntu/.rvm/gems/ruby-2.4.0'
}

set :passenger_restart_with_touch, true

set :rvm_type, :user
set :rvm_ruby_version, '2.4.0@otp_api'
set :rvm_roles, [:app, :web, :db]

set :keep_releases, 5

set :linked_files, %w{.env}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}

set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rvmsudo')

namespace :deploy do
  after :finishing, 'deploy:cleanup'
  after 'deploy:publishing', 'deploy:symlink:linked_files', 'deploy:symlink:linked_dirs', 'deploy:restart'
end

# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.7.6'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Active admin
gem 'active_admin_paranoia'
gem 'active_admin_sidebar', git: 'https://github.com/activeadmin-plugins/active_admin_sidebar.git'
gem 'activeadmin'
gem 'activeadmin-globalize', '~> 1.0.0.pre', github: 'fabn/activeadmin-globalize', branch: 'develop'
gem 'activeadmin_addons', '1.5'

gem 'sass-rails'
gem 'sassc-rails'
gem 'uglifier'

# Active Admin skins
gem 'active_skin'

# WYSIWYG
gem 'activeadmin_quill_editor'

# Graphs
gem 'chartkick'
gem 'groupdate'

gem 'devise'

# Soft Delete
gem 'paranoia', "~> 2.2"

# Rails and DB
gem 'activerecord-postgis-adapter'
gem 'pg',    '~> 0.18'
gem 'rails', '~> 5.1.7'
gem 'rgeo'
gem 'rgeo-geojson'

# API
#gem 'jsonapi-resources', '0.10.0'
# TODO: version 0.9.12 has problems with including nested relationships, did not work on observation endpoint
# leaving it as it is now. Better to bring up code coverage first as this gem is VERY unstable
# I included another MONKEY PATCH to fix error with nil relationships (that is fixed by this commit https://github.com/cerebris/jsonapi-resources/commit/0280f70ae481ac18b7abc659a6580a82b71d4175)
gem 'jsonapi-resources', '0.9.0'
gem 'oj'
gem 'oj_mimic_json'

# API Documentation
gem 'rspec_api_documentation', github: 'tsubik/rspec_api_documentation', branch: 'fix/open-api-parameter-format'
gem 'rswag-api'
gem 'rswag-ui'

# Activejob
gem 'sidekiq'

# Data
gem 'activerecord-import'
gem 'acts_as_list'
gem 'countries', require: false # for update translations job, so require only there
gem 'globalize', '5.2.0'
gem 'seed-fu'

# Validation
gem 'valid_url'

# Auth and Omniauth
gem 'bcrypt'
gem 'cancancan'
gem 'jwt'

# Uploads
gem 'carrierwave-base64'
gem 'mini_magick'

# Mail
gem 'sendgrid-ruby'

# File utilities
gem 'rubyzip', '~> 2.3.0'

# Changes monitoring
gem 'globalize-versioning'
gem 'paper_trail'

# Interactors
gem "interactor", "~> 3.0"

# Error Management
gem 'sentry-rails'
gem 'sentry-ruby'

group :development, :test do
  gem 'byebug',                    platform: :mri
  gem 'faker'
  gem 'rails-erd'
  gem 'rubocop', '~> 0.80.0', require: false
  gem 'rubocop-performance', '~> 1.5.2'
  gem 'rubocop-rails', '~> 2.4.2'
  gem 'webmock'
end

group :development do
  gem 'annotate'
  gem 'brakeman',                  require: false
  gem 'capistrano',                '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-env-config'
  gem 'capistrano-passenger'
  gem 'capistrano-rails',          '~> 1.2'
  gem 'capistrano-rvm'
  gem 'guard'
  gem 'listen',                    '~> 3.0.5'
  gem 'pry-rails'
  gem 'spring'
  gem 'spring-watcher-listen',     '~> 2.0.0'
end

group :test do
  gem 'bullet'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'factory_bot_rails'
  gem 'rspec-activejob'
  gem 'rspec-rails'
  gem 'rspec-request_snapshot', github: 'tsubik/rspec-request_snapshot', branch: 'fix/ignore-order'
  gem 'shoulda-matchers', '~> 4.0.1'
  gem 'simplecov'
  gem 'super_diff'
end

# Server
gem 'dotenv-rails'
gem 'puma'
gem 'rack-cors'
gem 'redis-rails'
gem 'tzinfo-data'

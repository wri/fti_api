# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.7.6'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'bootsnap', require: false

# Active admin
gem 'active_admin_paranoia'
gem 'active_admin_sidebar', git: 'https://github.com/activeadmin-plugins/active_admin_sidebar.git'
gem 'activeadmin'
gem 'activeadmin-globalize', github: 'tsubik/activeadmin-globalize', branch: 'rails-7'
gem 'activeadmin_addons'

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
# version 2.6.0 will not work in this app because until the way operator document is regenerated after destroy is changed
# here is the reason https://github.com/rubysherpas/paranoia/pull/485/files#diff-11d24643784dae175b47e4df1207f1184300711d4f728e730c06fbecf300cd7fR76-R77
# if model is not deleted in destroy action then everything is rolled back
gem 'paranoia', '~> 2.5.3'

# Rails and DB
gem 'activerecord-postgis-adapter'
gem 'pg'
gem 'rails', '~> 6.1.7'
gem 'rgeo'
gem 'rgeo-geojson'

# API
gem 'jsonapi-resources', '0.9.12'
gem 'oj'
gem 'oj_mimic_json'

# API Documentation
gem 'rspec_api_documentation', github: 'tsubik/rspec_api_documentation', branch: 'fix/open-api-parameter-format'
gem 'rswag-api'
gem 'rswag-ui'

# Activejob
gem 'sidekiq', '~> 5'

# Data
gem 'activerecord-import'
gem 'acts_as_list'
gem 'countries', require: false # for update translations job, so require only there
gem 'globalize'
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
gem 'letter_opener_web'
gem 'sendgrid-actionmailer'

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
  gem 'factory_bot_rails'
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
  gem 'i18n_generators'
  gem 'listen', '~> 3.3'
  gem 'pry-rails'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'spring'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'bullet'
  gem 'capybara'
  gem 'cuprite'
  gem 'database_cleaner'
  gem 'email_spec'
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

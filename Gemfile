# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Active admin
gem 'activeadmin'
gem 'activeadmin_addons'
gem 'activeadmin-globalize', '~> 1.0.0.pre', github: 'fabn/activeadmin-globalize', branch: 'develop'
gem 'active_admin_paranoia'
gem 'active_admin_sidebar', git: 'https://github.com/activeadmin-plugins/active_admin_sidebar.git'

gem 'devise'


# Soft Delete
gem 'paranoia', "~> 2.2"

# Active Admin skins
gem 'active_skin'
#gem 'active_admin_theme'
#gem "active_material", github: "vigetlabs/active_material"
#gem 'active_admin_flat_skin'
#gem 'face_of_active_admin'
#gem 'activeadmin_blaze_theme'
#gem 'flattened_active_admin'


# Rails and DB
gem 'pg',    '~> 0.18'
gem 'rails', '~> 5.0.2'

# API
gem 'jsonapi-resources'
gem 'oj'
gem 'oj_mimic_json'

# Data
gem 'activerecord-import'
gem 'globalize',                   github: 'globalize/globalize'
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

# Templating
gem 'slim-rails'

# Performance
gem 'newrelic_rpm'
gem 'oink'

group :development, :test do
  gem 'byebug',                    platform: :mri
  gem 'faker'
  gem 'rubocop',                   require: false
  gem 'webmock'
  gem 'rails-erd'
end

group :development do
  gem 'annotate'
  gem 'brakeman',                  require: false
  gem 'capistrano',                '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-env-config'
  gem 'capistrano-passenger'
  gem 'capistrano-rails',          '~> 1.2'
  gem 'capistrano-resque',         require: false
  gem 'capistrano-rvm'
  gem 'listen',                    '~> 3.0.5'
  gem 'pry-rails'
  gem 'spring'
  gem 'spring-watcher-listen',     '~> 2.0.0'
end

group :test do
  gem 'bullet'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'factory_girl_rails'
  gem 'rspec-activejob'
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'timecop'
end

# Server
gem 'dotenv-rails'
gem 'puma'
gem 'rack-cors'
gem 'rails_12factor',              group: :production
gem 'redis-rails'
gem 'resque'
gem 'resque-scheduler'
gem 'resque_mailer'
gem 'tzinfo-data'

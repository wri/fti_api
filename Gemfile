# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.2.3"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "bootsnap", require: false

# Active admin
gem "active_admin_paranoia", git: "https://github.com/tsubik/active_admin_paranoia.git"
gem "active_admin_sidebar", git: "https://github.com/activeadmin-plugins/active_admin_sidebar.git"
gem "activeadmin"
gem "activeadmin-globalize", github: "tsubik/activeadmin-globalize", branch: "custom"
# looks like merging this https://github.com/platanus/activeadmin_addons/pull/442/files caused raising Formtastic::UnsupportedEnumCollection for multiple selects with enum values
gem "activeadmin_addons", "~> 1.9.0"

gem "sass-rails"
gem "sassc-rails"
gem "uglifier"
gem "sprockets-rails"

# Active Admin skins
gem "active_skin"

# WYSIWYG
gem "activeadmin_quill_editor"

# Graphs
gem "chartkick"
gem "groupdate"

gem "devise"

# Soft Delete
gem "paranoia"

# Rails and DB
gem "activerecord-postgis-adapter"
gem "pg"
gem "rails", "~> 7.0.4"
gem "rgeo"
gem "rgeo-geojson"

# API
gem "jsonapi-resources", "0.9.12"
gem "oj"
gem "oj_mimic_json"

# API Documentation
gem "rspec_api_documentation", github: "tsubik/rspec_api_documentation", branch: "fix/open-api-parameter-format"
gem "rswag-api"
gem "rswag-ui"

# Activejob
gem "sidekiq"

# Data
gem "activerecord-import"
gem "acts_as_list"
gem "countries", require: false # for update translations job, so require only there
gem "globalize"

# Validation
gem "valid_url"

# Auth and Omniauth
gem "bcrypt"
gem "cancancan"
gem "jwt"

# Uploads
gem "carrierwave-base64"
gem "mini_magick"

# Mail
gem "mjml-rails"
gem "letter_opener_web"
gem "sendgrid-actionmailer"

# File utilities
gem "rubyzip", "~> 2.3.0"

# Changes monitoring
gem "globalize-versioning", github: "globalize/globalize-versioning", branch: "main"
gem "paper_trail"

# Interactors
gem "interactor", "~> 3.0"

# Error Management
gem "sentry-rails"
gem "sentry-ruby"

# Utilities
gem "http"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "faker"
  gem "rails-erd"
  gem "rubocop-rails"
  gem "standard"
  gem "webmock"
end

group :development do
  gem "annotate"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "capistrano", "~> 3.6"
  gem "capistrano-bundler"
  gem "capistrano-db-tasks", require: false
  gem "capistrano-env-config"
  gem "capistrano-passenger"
  gem "capistrano-rails", "~> 1.2"
  gem "capistrano-rvm"
  gem "i18n_generators"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 2.0"
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem "web-console", ">= 4.1.0"
end

group :test do
  gem "bullet"
  gem "capybara"
  gem "cuprite"
  gem "database_cleaner"
  gem "email_spec"
  gem "rspec-activejob"
  gem "rspec-rails"
  gem "rspec-request_snapshot", github: "tsubik/rspec-request_snapshot", branch: "fix/ignore-order"
  gem "shoulda-matchers", "~> 4.0.1"
  gem "simplecov"
  gem "super_diff"
end

# Server
gem "dotenv-rails"
gem "puma"
gem "rack-cors"
gem "redis-rails"
gem "tzinfo-data"

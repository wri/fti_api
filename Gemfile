# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.2"

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
gem "activeadmin_addons"

gem "sass-rails"
gem "sassc-rails"
gem "uglifier"
gem "sprockets-rails"

# Active Admin skins
gem "active_skin"

# WYSIWYG
gem "activeadmin_quill_editor", "~> 1.0"

# Graphs
gem "chartkick"
gem "groupdate"

gem "devise"

# Soft Delete
gem "paranoia"

# Rails and DB
gem "activerecord-postgis-adapter"
gem "pg"
gem "rails", "~> 7.2.2"
gem "rgeo"
gem "rgeo-geojson"
gem "gdal"

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

# Cron
gem "whenever", require: false

# Data
gem "activerecord-import"
gem "acts_as_list"
gem "globalize"

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
gem "globalize-versioning", github: "tsubik/globalize-versioning", branch: "custom"
gem "paper_trail"

# Translations
gem "google-cloud-translate"

# Error Management
gem "sentry-rails"
gem "sentry-ruby"

# TODO: jsonapi-resources is not compatible with this rack PR https://github.com/rack/rack/pull/2137 (ver 3.1.0), waiting for a patch
# more info here https://github.com/cerebris/jsonapi-resources/pull/1457
# remove version contstraint when above PR is merged and backported to ver 0.9.12
gem "rack", "~> 3.0.11"

# Utilities
gem "http"
gem "nokogiri"
gem "warning", require: false # for silencing certain warnings, will require before boot in warings_silencer.rb

# Only used in rake tasks
gem "countries", require: false # for update translations job, so require only there

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rubocop-rails", require: false
  gem "standard", require: false
end

group :development do
  gem "annotate"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "capistrano", "~> 3.6", require: false
  gem "capistrano-bundler", require: false
  gem "capistrano-db-tasks", require: false
  gem "capistrano-env-config", require: false
  gem "capistrano-maintenance", require: false
  gem "capistrano3-puma", "~> 6.0.0.beta", require: false
  gem "capistrano-rails", "~> 1.2", require: false
  gem "capistrano-rvm", require: false
  gem "i18n_generators"

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 2.0"
  gem "web-console", ">= 4.1.0"
end

group :test do
  gem "bullet"
  gem "capybara"
  gem "cuprite"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "faker"
  gem "parallel_tests"
  gem "rspec-collection_matchers"
  gem "rspec-rails"
  gem "rspec-request_snapshot", github: "tsubik/rspec-request_snapshot", branch: "fix/ignore-order"
  gem "shoulda-matchers", "~> 4.0.1"
  gem "simplecov"
  gem "spring-commands-rspec"
  gem "super_diff"
  gem "webmock"
end

# Server
gem "dotenv-rails"
gem "puma"
gem "rack-cors"
gem "redis-rails"
gem "tzinfo-data"

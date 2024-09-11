# frozen_string_literal: true

user = ENV["SSH_USER"]
server ENV["STAGING_HOST"],
  user: user,
  roles: %w[web app db], primary: true

set :ssh_options, {
  forward_agent: true,
  auth_methods: %w[publickey password],
  password: fetch(:password)
}

set :branch, ENV.fetch("BRANCH") { "staging" }
set :deploy_to, "/var/www/otp-api"
set :rails_env, "staging"

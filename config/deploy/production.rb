# frozen_string_literal: true

user = ENV["SSH_USER"]
server ENV["PRODUCTION_HOST"],
  user: user,
  roles: %w[web app db], primary: true

set :ssh_options, {
  forward_agent: true,
  auth_methods: %w[publickey password],
  password: fetch(:password)
}

set :branch, ENV.fetch("BRANCH") { "master" }
set :deploy_to, "/var/www/otp-api"

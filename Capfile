# frozen_string_literal: true

# Load DSL and set up stages
require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rvm"
require "capistrano/puma"
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"

require "capistrano/env-config"
require "capistrano-db-tasks"
require "capistrano/maintenance"
require "whenever/capistrano"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

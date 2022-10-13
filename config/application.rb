# frozen_string_literal: true

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"
require 'carrierwave'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FtiApi
  class Application < Rails::Application
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')
    config.load_defaults 5.1

    # ActiveJob
    config.active_job.queue_adapter = :sidekiq

    config.api_only = false

    config.generators do |g|
      g.template_engine nil
      g.test_framework :rspec,
                       fixtures: true,
                       routing_specs: true,
                       controller_specs: false,
                       request_specs: true
    end
  end
end

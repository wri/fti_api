# frozen_string_literal: true

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"
require "sprockets/railtie"
require 'carrierwave'
require_relative '../lib/rack/health_check'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# ActiveSupport::Deprecation.silenced = true

module FtiApi
  class Application < Rails::Application
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')
    config.load_defaults 6.0
    config.autoloader = :classic

    # ActiveJob
    config.active_job.queue_adapter = :sidekiq

    config.api_only = false
    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    app_url = URI.parse(ENV.fetch('APP_URL', 'http://localhost:3000'))
    Rails.application.routes.default_url_options = {
      host: app_url.host,
      port: app_url.port,
      protocol: app_url.scheme
    }

    config.generators do |g|
      g.template_engine nil
      g.test_framework :rspec,
                       fixtures: true,
                       routing_specs: true,
                       controller_specs: false,
                       request_specs: true
    end

    config.middleware.insert_after Rails::Rack::Logger, Rack::HealthCheck
  end
end

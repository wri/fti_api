# frozen_string_literal: true

require_relative "warnings_silencer"
require_relative "boot"

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
require "carrierwave"
require_relative "../lib/rack/health_check"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# ActiveSupport::Deprecation.silenced = true

module FtiApi
  class Application < Rails::Application
    config.load_defaults 7.2
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[tasks rack])

    # for paper trail versioning
    # TODO: switch paper_trail to jsonb columns instead of text columns and yaml serialization
    # then remove the following line
    config.active_record.use_yaml_unsafe_load = true

    # ActiveJob
    config.active_job.queue_adapter = :sidekiq

    config.api_only = false
    config.action_mailer.preview_paths << "#{Rails.root}/spec/mailers/previews"

    config.i18n.fallbacks = [I18n.default_locale]

    app_url = URI.parse(ENV.fetch("APP_URL", "http://localhost:3000"))
    Rails.application.routes.default_url_options = {
      host: app_url.host,
      port: app_url.port,
      protocol: app_url.scheme
    }
    config.asset_host = app_url.to_s unless Rails.env.test?

    config.generators do |g|
      g.system_tests nil
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

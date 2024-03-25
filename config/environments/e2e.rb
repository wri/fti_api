# frozen_string_literal: true

require "active_support/core_ext/integer/time"
require_relative "production"

Rails.application.configure do
  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store
  config.cache_store = :file_store, "#{Rails.root}/tmp/cache-e2e/"
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{2.days.to_i}"
  }
  config.public_file_server.enabled = true

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "sc_api_test_#{Rails.env}"
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener_web
end

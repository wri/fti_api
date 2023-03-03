# frozen_string_literal: true

module Rack
  class HealthCheck
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless env['PATH_INFO'] == '/health_check'

      [
        healthy? ? 200 : 503,
        { 'Content-Type' => 'application/json' },
        [message]
      ]
    end

    private

    def message
      {
        "status": healthy? ? 'ok' : 'error',
        "database": database_connected?,
        "redis": redis_connected?,
        "sidekiq": sidekiq_running?
      }.to_json
    end

    def healthy?
      database_connected? && redis_connected? && sidekiq_running?
    end

    def database_connected?
      ApplicationRecord.connection.select_value('SELECT 1') == 1
    rescue StandardError
      false
    end

    def redis_connected?
      Redis.current.ping == 'PONG'
    rescue StandardError
      false
    end

    def sidekiq_running?
      Sidekiq::ProcessSet.new.size.positive?
    rescue StandardError
      false
    end
  end
end

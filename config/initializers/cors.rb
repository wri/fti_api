# frozen_string_literal: true

if Rails.env.development? || Rails.env.e2e?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/)
      resource "*", headers: :any, methods: %i[get post put patch delete options head]
    end
  end
end

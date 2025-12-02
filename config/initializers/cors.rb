# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(/\Ahttps:\/\/([a-z0-9-]+\.)*opentimberportal\.org\z/) if Rails.env.production? || Rails.env.staging?
    resource "*", headers: :any, methods: %i[get post put patch delete options head]
  end
end

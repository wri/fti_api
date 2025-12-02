# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.production? || Rails.env.staging?
      origins(/\Ahttps:\/\/([a-z0-9-]+\.)*opentimberportal\.org\z/)
    else
      origins "*"
    end
    resource "*", headers: :any, methods: %i[get post put patch delete options head]
  end
end

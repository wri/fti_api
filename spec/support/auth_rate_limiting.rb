# frozen_string_literal: true

RSpec.configure do |config|
  config.after do
    AuthRateLimiting::STORE.clear
  end
end

require "capybara/cuprite"
require "rails_helper"

Capybara.default_max_wait_time = 2
Capybara.default_normalize_ws = true

cuprite_options = {
  window_size: [1200, 800],
  browser_options: {
    "no-sandbox": nil
  },
  timeout: 120,
  # Increase Chrome startup wait time (required for stable CI builds)
  process_timeout: 120,
  inspector: ENV["INSPECTOR"],
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false])
}

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, **cuprite_options)
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :cuprite

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Select2Helper, type: :system
  config.include CupriteHelpers, type: :system
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host
    ex.run
    Rails.application.default_url_options[:host] = was_host
  end

  config.before(:each, type: :system) do
    # not sure why but options needs to be passed here again starting in Rails 7
    # otherwise headless or inspector options are not respected
    driven_by :cuprite, screen_size: [1200, 800], options: cuprite_options
  end
end

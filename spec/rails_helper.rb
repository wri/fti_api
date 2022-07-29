# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'paper_trail/frameworks/rspec'

require 'integration_helper'
require 'importer_helper'

require 'rspec/rails'
require 'super_diff/rspec-rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'factory_bot_rails'
require 'shoulda/matchers'
require 'devise'

require 'api_docs_helper'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/models/concerns/**/*.rb')].each {|f| require f}
Dir[Rails.root.join('spec/integration/shared_examples/**/*.rb')].each {|f| require f}

ActiveRecord::Migration.maintain_test_schema!

# Configuration for Shoulda::Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec

    # Keep as many of these lines as are necessary:
    with.library :active_record
    with.library :rails
  end
end

RspecApiDocumentation.configure do |config|
  config.format = [:openApi]

  config.configurations_dir = Rails.root.join("spec", "support", "docs")

  config.api_name = 'Open Timber Portal API documentation'
  config.api_explanation = 'API Documentation for the OTP API.'
  config.io_docs_protocol = %w(http https)

  config.response_headers_to_include = []
  config.keep_source_order = true
  config.request_body_formatter = :json
end

RSpec.configure do |config|
  config.include ErrorResponses
  config.include IntegrationHelper, type: :request
  config.include ImporterHelper, type: :importer
  config.extend APIDocsHelpers

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.request_snapshots_dir = "spec/fixtures/snapshots"
  # adding dynamic attributes for snapshots, small medium original are for active storage links
  config.request_snapshots_dynamic_attributes = %w[id created_at updated_at]

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  config.when_first_matching_example_defined(:db) do
    require 'support/db'
  end

  config.after(:each) do
    if Rails.env.test? || Rails.env.cucumber?
      FileUtils.rm_rf(Dir["#{Rails.root}/spec/support/uploads"])
    end
  end

  config.around(realistic_error_responses: true) do |example|
    respond_without_detailed_exceptions(&example)
  end

  if Bullet.enable?
    config.before(:each, type: :controller) do
      Bullet.start_request
    end

    config.after(:each, type: :controller) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  config.extend APIDocsHelpers
  config.include FactoryBot::Syntax::Methods
  config.order = 'random'
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers
end

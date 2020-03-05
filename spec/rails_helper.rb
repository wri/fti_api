# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'codeclimate-test-reporter'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter 'app/channels'
  add_filter 'app/constraints'

  add_group 'Backoffice', 'app/admin'
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Resources', 'app/resources'
  add_group 'Uploaders', 'app/uploaders'
  add_group 'Services', 'app/services'
  add_group 'Serializers', 'app/serializers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Importers', 'app/importers'
  add_group 'Importers Lib', 'lib/file_data_import'
  add_group 'Mailers', 'app/mailers'
  add_group 'Initializers', 'config/initializers'
end

require 'spec_helper'
require 'rspec/rails'

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

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

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

  if Bullet.enable?
    config.before(:each, type: :controller) do
      Bullet.start_request
    end

    config.after(:each, type: :controller) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  config.include FactoryBot::Syntax::Methods
  config.order = 'random'
  config.include Devise::Test::ControllerHelpers, :type => :controller
end

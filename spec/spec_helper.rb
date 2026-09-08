require "simplecov"

SimpleCov.start "rails" do
  skip "/spec/"
  skip "app/channels"
  skip "app/constraints"
  skip "lib/tasks"

  group "Backoffice", "app/admin"
  group "Models", "app/models"
  group "Controllers", "app/controllers"
  group "Resources", "app/resources"
  group "Uploaders", "app/uploaders"
  group "Services", "app/services"
  group "Serializers", "app/serializers"
  group "Helpers", "app/helpers"
  group "Importers", "app/importers"
  group "Importers Lib", "lib/file_data_import"
  group "Mailers", "app/mailers"
  group "Initializers", "config/initializers"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

require "simplecov"

SimpleCov.start "rails" do
  add_filter "/spec/"
  add_filter "app/channels"
  add_filter "app/constraints"
  add_filter "lib/tasks"

  add_group "Backoffice", "app/admin"
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Resources", "app/resources"
  add_group "Uploaders", "app/uploaders"
  add_group "Services", "app/services"
  add_group "Serializers", "app/serializers"
  add_group "Helpers", "app/helpers"
  add_group "Importers", "app/importers"
  add_group "Importers Lib", "lib/file_data_import"
  add_group "Mailers", "app/mailers"
  add_group "Initializers", "config/initializers"
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

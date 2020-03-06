require 'integration_helper'
require 'importer_helper'
require 'rails_helper'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include IntegrationHelper, type: :request
  config.include ImporterHelper, type: :importer
  config.extend APIDocsHelpers
end

RspecApiDocumentation.configure do |config|
  config.format = [:openApi]

  config.configurations_dir = Rails.root.join("spec", "support", "docs")

  config.api_name = 'Open Timber Portal API documentation'
  config.api_explanation = 'API Documentation for the OTP API.'
  config.io_docs_protocol = %w(http https)

  config.keep_source_order = true
  config.request_body_formatter = :json
end
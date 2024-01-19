# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.to_s + "/doc/api"
end

Rswag::Ui.configure do |c|
  c.openapi_endpoint "/docs/open_api.json", "API V1 Docs" if Rails.env.development?
  c.openapi_endpoint "/api/docs/open_api.json", "API V1 Docs" unless Rails.env.development?
end

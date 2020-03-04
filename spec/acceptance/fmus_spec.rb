require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Fmus' do
  explanation "FMUs resource"

  header "Content-Type", "application/vnd.api+json"

  authentication :apiKey, "Bearer #{User.first.api_key.access_token}" , name: 'OTP-API-KEY'

  get "/fmus" do
    example "Listing fmus" do
      do_request

      expect(status).to eq 200
    end
  end
end
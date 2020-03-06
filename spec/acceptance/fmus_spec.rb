require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Fmus' do
  explanation "FMUs resource"

  let!(:web_user) { FactoryBot.create(:admin) }
  let!(:web_token) { 'Bearer ' + web_user.api_key.access_token }

  let!(:admin) { FactoryBot.create(:admin) }
  let!(:admin_token) { 'Bearer ' + admin.api_key.access_token }

  header "Content-Type", "application/vnd.api+json"

  authentication :apiKey, :web_token , name: 'OTP-API-KEY'

  get "/fmus" do
    example "Listing fmus" do
      do_request

      expect(status).to eq 200
    end
  end
end
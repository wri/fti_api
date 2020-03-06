require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Countries' do
  explanation "Countries resource"

  let!(:web_user) { FactoryBot.create(:admin) }
  let!(:web_token) { 'Bearer ' + web_user.api_key.access_token }

  let!(:admin) { FactoryBot.create(:admin) }
  let!(:admin_token) { 'Bearer ' + admin.api_key.access_token }

  header "Content-Type", "application/vnd.api+json"
  header 'Authorization', :admin_token

  authentication :apiKey, :web_token , name: 'OTP-API-KEY'

  get "/countries" do
    example "Listing countries" do
      do_request

      expect(status).to eq 200
    end
  end
end
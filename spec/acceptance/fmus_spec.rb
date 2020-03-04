require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Fmus' do
  #let(:user) { FactoryBot.create(:webuser) }
  #  webuser = FactoryBot.create(:webuser)
  #puts webuser
  explanation "FMUs resource"

  header "Content-Type", "application/vnd.api+json"

  #authentication :apiKey, 'OTP-API-KEY', name: User.first.api_key.access_token

  get "/fmus" do
    example "Listing fmus" do
      do_request

      expect(status).to eq 200
    end
  end
end
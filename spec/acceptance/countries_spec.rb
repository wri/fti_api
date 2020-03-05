require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Countries' do
  explanation "Countries resource"

  admin = User.joins(:user_permission).where(user_permissions: { user_role: 'admin' }).first || FactoryBot.create(:admin)
  admin_token = admin.api_key.access_token

  web_user = User.find_by(name: 'Web user')
  web_token = web_user.api_key.access_token

  header "Content-Type", "application/vnd.api+json"
  header 'Authorization', "Bearer #{admin_token}"

  authentication :apiKey, "Bearer #{web_token}" , name: 'OTP-API-KEY'

  get "/countries" do
    example "Listing countries" do
      do_request

      expect(status).to eq 200
    end
  end
end
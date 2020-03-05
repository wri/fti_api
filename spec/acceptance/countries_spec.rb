require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Countries' do
  explanation "Countries resource"

  #admin = User.joins(:user_permission).where(user_permissions: { user_role: 'admin' }).first || FactoryBot.create(:admin)
  #admin_token = admin.api_key.access_token
  #
  #web_user = User.find_by(name: 'Web user')
  #web_token = web_user.api_key.access_token

  let!(:web_user) { FactoryBot.create(:admin) }
  let!(:web_token) { 'Bearer ' + web_user.api_key.access_token }

  let!(:admin) { FactoryBot.create(:admin) }
  let!(:admin_token) { 'Bearer ' + admin.api_key.access_token }

  header "Content-Type", "application/vnd.api+json"
  header 'Authorization', :admin_token

  header 'OTP-API-KEY', :web_token
  #authentication :apiKey, "Bearer #{web_token}" , name: 'OTP-API-KEY'

  get "/countries" do
    example "Listing countries" do
      do_request

      expect(status).to eq 200
    end
  end
end
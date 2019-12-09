require 'acceptance_helper'

module V1
  describe 'API Key', type: :request do
    context 'Show users for valid api key' do
      before(:each) do
        @webuser = create(:webuser)
        token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

        @headers = {
          # "ACCEPT" => "application/json",
          "HTTP_OTP_API_KEY" => "Bearer #{token}"
        }
      end

      describe 'Request with valid api key' do
        it 'Get users list' do
          get '/users', headers: @headers
          expect(status).to eq(200)
        end
      end

      describe 'Request with invalid api key' do
        let!(:error) {
          { errors: [{ status: '401', title: 'Sorry invalid API token' }] }
        }

        it 'Get users list' do
          get '/users'
          expect(status).to eq(401)
          expect(body).to   eq(error.to_json)
        end
      end
    end
  end
end

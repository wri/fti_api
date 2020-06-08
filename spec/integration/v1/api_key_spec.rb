require 'rails_helper'

module V1
  describe 'API Key', type: :request do
    context 'Show users for valid api key' do

      describe 'Request with valid api key' do
        it 'Get users list' do
          get '/users', headers: admin_headers
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
          expect(parsed_body).to eq(error)
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET #health_check' do
    before { get '/health_check' }

    it 'returns correct response' do
      expect(response).to have_http_status(:ok)
      expect(parsed_body).to include(status: 'ok', database: true)
    end
  end
end

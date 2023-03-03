require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET #health_check' do
    context 'when all is good' do
      before { allow(Redis).to receive(:new).and_return(double(ping: 'PONG')) }
      before { allow(Sidekiq::ProcessSet).to receive(:new).and_return(double(size: 1)) }

      before { get '/health_check' }

      it 'returns correct response' do
        expect(response).to have_http_status(:ok)
        expect(parsed_body).to include(status: 'ok', database: true, redis: true, sidekiq: true)
      end
    end

    context 'when redis is down' do
      before { allow(Redis).to receive(:new).and_raise(StandardError) }

      before { get '/health_check' }

      it 'returns correct response' do
        expect(response).to have_http_status(:service_unavailable)
        expect(parsed_body).to include(status: 'error', redis: false)
      end
    end

    context 'when sidekiq is down' do
      before { allow(Redis).to receive(:new).and_return(double(ping: 'PONG')) }
      before { allow(Sidekiq::ProcessSet).to receive(:new).and_return(double(size: 0)) }

      before { get '/health_check' }

      it 'returns correct response' do
        expect(response).to have_http_status(:service_unavailable)
        expect(parsed_body).to include(status: 'error', sidekiq: false)
      end
    end

    context 'when database is down' do
      before { allow(Redis).to receive(:new).and_return(double(ping: 'PONG')) }
      before { allow(Sidekiq::ProcessSet).to receive(:new).and_return(double(size: 1)) }
      before { allow(ApplicationRecord).to receive(:connection).and_raise(StandardError) }

      before { get '/health_check' }

      it 'returns correct response' do
        expect(response).to have_http_status(:service_unavailable)
        expect(parsed_body).to include(status: 'error', database: false)
      end
    end
  end
end

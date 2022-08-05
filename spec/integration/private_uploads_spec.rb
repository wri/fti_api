require 'rails_helper'

describe 'Private Uploads', :realistic_error_responses, type: :request do
  let(:admin) { create(:admin) }

  before do
    @observation_report = create(:observation_report)
    @observation_report.destroy!
    @observation_report.reload
  end

  context 'as admin user' do
    before { sign_in admin }

    context 'with valid parameters' do
      before { get @observation_report.attachment.url }

      it 'downloads expected file' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'with wrong parameters' do
      before { get '/private/uploads/../../../file' }

      it 'returns error' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'as not admin user' do
    context 'with valid parameters' do
      before { get @observation_report.attachment.url }

      it 'does not download expected file' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

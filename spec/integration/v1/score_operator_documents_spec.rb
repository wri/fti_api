require 'rails_helper'

module V1
  describe 'ScoreOperatorDocuments', type: :request do
    let(:operator_1) { create(:operator, fa_id: 'forest atlas id1') }
    let(:operator_2) { create(:operator, fa_id: 'forest atlas id2') }

    before do
      create_list(:operator_document, 2, operator: operator_2)
      create(:operator_document, operator: operator_1)
    end

    describe 'index' do
      it 'errors without operator filter' do
        get '/score-operator-documents', headers: non_api_webuser_headers

        expect(status).to eq(400)
        expect(parsed_body[:error]).to eq('You must provide an operator')
      end

      describe 'filters' do
        it 'filter by operator id' do
          get "/score-operator-documents?filter[operator]=#{operator_1.id}", headers: webuser_headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(1)
        end
      end
    end
  end
end

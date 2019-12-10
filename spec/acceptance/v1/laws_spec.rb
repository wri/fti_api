require 'rails_helper'

module V1
  describe 'Law', type: :request do
    let(:operator) { FactoryBot.create(:operator_user) }

    it_behaves_like "jsonapi-resources__show", Law.model_name

    it_behaves_like(
      "jsonapi-resources__create",
      Law.model_name,
      { 'min-fine': 1, 'max-fine': 2 },
      { 'min-fine': 1, 'max-fine': -2 },
      [422, 100, { 'max-fine': ["must be greater than or equal to 0"] }]
    )

    it_behaves_like(
      "jsonapi-resources__edit",
      Law.model_name,
      { 'min-fine': 1, 'max-fine': 2 },
      { 'min-fine': 1, 'max-fine': -2 },
      [422, 100, { 'max-fine': ["must be greater than or equal to 0"] }]
    )

    it_behaves_like "jsonapi-resources__delete", Law, Law.model_name

    context 'Pagination and sort for laws' do
      let!(:laws) { FactoryBot.create_list(:law, 6) }

      it 'Show list of laws for first page with per pege param' do
        get '/laws?page[number]=1&page[size]=3', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of laws for second page with per pege param' do
        get '/laws?page[number]=2&page[size]=3', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(3)
      end
    end

    context 'Create laws' do
      describe 'For not admin user' do
        let(:operator_headers) { authorize_headers(operator.id) }

        it 'Do not allows to create law by not admin user' do
          post('/laws',
               params: jsonapi_params('laws', nil, { 'min-fine': 1, 'max-fine': 3 }),
               headers: operator_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end
  end
end

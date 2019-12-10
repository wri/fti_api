require 'rails_helper'

module V1
  describe 'Governments', type: :request do
    let(:ngo) { FactoryBot.create(:ngo) }

    let!(:government) { FactoryBot.create(:government, government_entity: '00 Government one') }
    let(:error) { jsonapi_errors(422, 100, { 'government-entity': ["can't be blank"] }) }

    # need to be an admin!
    it_behaves_like "jsonapi-resources__show", Government.model_name

    it_behaves_like(
      "jsonapi-resources__create",
      Government.model_name,
      { 'government-entity': 'Government one' },
      { 'government-entity': '' },
      [422, 100, { 'government-entity': ["can't be blank"] }]
    )

    it_behaves_like(
      "jsonapi-resources__edit",
      Government.model_name,
      { 'government-entity': 'Government one' },
      { 'government-entity': '' },
      [422, 100, { 'government-entity': ["can't be blank"] }]
    )

    it_behaves_like "jsonapi-resources__delete", Government, Government.model_name

    context 'Pagination and sort for governments' do
      let!(:country) { FactoryBot.create(:country, name: 'Spain') }

      let!(:governments) {
        governments = []
        governments << FactoryBot.create_list(:government, 4)
        governments << FactoryBot.create(:government, government_entity: 'ZZZ Next first one Spain', country: country)
      }

      let(:country_id) { Government.find_by(government_entity: 'ZZZ Next first one Spain').country.id }

      it 'Show list of governments for first page with per page param' do
        get '/governments?page[number]=1&page[size]=3', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of governments for second page with per page param' do
        get '/governments?page[number]=2&page[size]=3', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of governments for sort by government_entity' do
        get '/governments?sort=government_entity', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:government_entity]).to eq('00 Government one')
      end

      it 'Show list of governments for sort by government_entity DESC' do
        get '/governments?sort=-government_entity', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:government_entity]).to eq('ZZZ Next first one Spain')
      end

      it 'Filter governments by country and sort by government_entity ASC' do
        get "/governments?country=#{country_id}&sort=government_entity", headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(1)
        expect(parsed_data[0][:attributes][:government_entity]).to match('Spain')
      end
    end

    context 'Edit governments' do
      describe 'For not admin user' do
        let(:ngo_headers) { authorize_headers(ngo.id) }

        it 'Do not allow to update government by a non admin user' do
          patch("/governments/#{government.id}",
                params: jsonapi_params('governments', government.id, { 'government-entity': 'Government one' }),
                headers: ngo_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end
  end
end

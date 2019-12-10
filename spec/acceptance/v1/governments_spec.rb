require 'rails_helper'

module V1
  describe 'Governments', type: :request do
    let(:ngo) { FactoryBot.create(:ngo) }

    let!(:government) { FactoryBot.create(:government, government_entity: '00 Government one') }
    let(:error) { jsonapi_errors(422, 100, { 'government-entity': ["can't be blank"] }) }

    context 'Show governments' do
      it 'Get governments list' do
        get '/governments', headers: webuser_headers
        expect(status).to eq(200)
      end

      it 'Get specific government' do
        get "/governments/#{government.id}", headers: webuser_headers
        expect(status).to eq(200)
      end
    end


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

    context 'Create governments' do
      describe 'For admin user' do
        it 'Returns error object when the government cannot be created by admin' do
          post('/governments',
               params: jsonapi_params('governments', nil, { 'government-entity': '' }),
               headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the government was successfully created by admin' do
          post('/governments',
               params: jsonapi_params('governments', nil, { 'government-entity': 'Government one' }),
               headers: admin_headers)

          expect(status).to eq(201)
          expect(parsed_data[:id]).not_to be_empty
          expect(parsed_attributes[:'government-entity']).to eq('Government one')
        end
      end

      describe 'For not admin user' do
        it 'Do not allow to create governments by a non admin user' do
          post('/governments',
               params: jsonapi_params('governments', nil, { 'government-entity': 'Government one' }),
               headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Edit governments' do
      describe 'For admin user' do
        it 'Returns error object when the government cannot be updated by admin' do
          patch("/governments/#{government.id}",
                params: jsonapi_params('governments', government.id, { 'government-entity': '' }),
                headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success when the government was successfully updated by admin' do
          patch("/governments/#{government.id}",
                params: jsonapi_params('governments', government.id, { 'government-entity': 'Government one one' }),
                headers: admin_headers)

          expect(status).to eq(200)
          expect(parsed_attributes[:'government-entity']).to eq('Government one one')
        end
      end

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

    context 'Delete governments' do
      describe 'For admin user' do
        it 'Returns success object when the government was successfully deleted by admin' do
          delete("/governments/#{government.id}", headers: admin_headers)

          expect(status).to eq(204)
          expect(Government.exists?(government.id)).to be_falsey
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to delete governments by a non admin user' do
          delete("/governments/#{government.id}", headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
          expect(Government.exists?(government.id)).to be_truthy
        end
      end
    end
  end
end

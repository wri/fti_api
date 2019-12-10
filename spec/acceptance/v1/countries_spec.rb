require 'rails_helper'

module V1
  describe 'Countries', type: :request do
    let(:ngo)   { FactoryBot.create(:ngo)   }

    let!(:country) { FactoryBot.create(:country, name: '00 Country one') }
    let(:error) { jsonapi_errors(422, 100, { iso: ["can't be blank"] }) }

    context 'Show countries' do
      it 'Get countries list' do
        get '/countries', headers: webuser_headers
        expect(status).to eq(200)
      end

      it 'Get specific country' do
        get "/countries/#{country.id}", headers: webuser_headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for countries' do
      let!(:countries) {
        countries = []
        countries << FactoryBot.create_list(:country, 4)
        countries << FactoryBot.create(:country, name: 'ZZZ Next first one', is_active: false)
      }

      it 'Show list of countries for first page with per pege param' do
        get '/countries?page[number]=1&page[size]=3', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of countries for second page with per pege param' do
        get '/countries?page[number]=2&page[size]=3', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of countries for sort by name' do
        get '/countries?sort=name', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:name]).to eq('00 Country one')
      end

      it 'Show list of countries for sort by name DESC' do
        get '/countries?sort=-name', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:name]).to eq('ZZZ Next first one')
      end

      it 'Filter countries by active' do
        get '/countries?is_active=true', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(5)
      end

      it 'Filter countries by inactive' do
        get '/countries?is_active=false', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(1)
      end

      it 'Load short list of countries' do
        get '/countries?short=true&is_active=false', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(1)
        expect(parsed_data[0][:attributes][:name]).to eq('ZZZ Next first one')
      end
    end

    context 'Create countries' do
      describe 'For admin user' do
        it 'Returns error object when the country cannot be created by admin' do
          post('/countries',
               params: jsonapi_params('countries', nil, { name: 'Test' }),
               headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the country was seccessfully created by admin' do
          post('/countries',
               params: jsonapi_params('countries', nil, { name: 'Country one', iso: 'COO' }),
               headers: admin_headers)

          expect(status).to eq(201)
          expect(parsed_data[:id]).not_to be_empty
          expect(parsed_attributes[:name]).to eq('Country one')
          expect(parsed_attributes[:iso]).to eq('COO')
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to create country by not admin user' do
          post('/countries',
               params: jsonapi_params('countries', nil, { name: 'Country one', iso: 'COO' }),
               headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Edit countries' do
      describe 'For admin user' do
        it 'Returns error object when the country cannot be updated by admin' do
          patch("/countries/#{country.id}",
                params: jsonapi_params('countries', country.id, { iso: '' }),
                headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the country was seccessfully updated by admin' do
          patch("/countries/#{country.id}",
                params: jsonapi_params('countries', country.id, { name: 'Country one one', iso: 'COO' }),
                headers: admin_headers)

          expect(status).to eq(200)
          expect(parsed_attributes[:name]).to eq('Country one one')
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to update country by not admin user' do
          patch("/countries/#{country.id}",
                params: jsonapi_params('countries', country.id, { name: 'Country one one', iso: 'COO' }),
                headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Delete countries' do
      describe 'For admin user' do
        it 'Returns success object when the country was seccessfully deleted by admin' do
          delete("/countries/#{country.id}", headers: admin_headers)

          expect(status).to eq(204)
          expect(Country.exists?(country.id)).to be_falsey
        end
      end

      describe 'For not admin user' do
        let(:ngo_headers) { authorize_headers(ngo.id) }

        it 'Do not allows to delete country by not admin user' do
          delete("/countries/#{country.id}", headers: ngo_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
          expect(Country.exists?(country.id)).to be_truthy
        end
      end
    end
  end
end

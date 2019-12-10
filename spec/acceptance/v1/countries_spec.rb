require 'rails_helper'

module V1
  describe 'Countries', type: :request do
    let(:ngo) { FactoryBot.create(:ngo) }
    let(:country) { FactoryBot.create(:country, name: '00 Country one') }

    it_behaves_like "jsonapi-resources__show", Country.model_name

    it_behaves_like(
      "jsonapi-resources__create",
      Country.model_name,
      { name: 'Country one', iso: 'COO' },
      { name: 'Country one', iso: '' },
      [422, 100, { iso: ["can't be blank"] }]
    )

    it_behaves_like(
      "jsonapi-resources__edit",
      Country.model_name,
      { name: 'Country two', iso: 'COO' },
      { name: 'Country two', iso: '' },
      [422, 100, { iso: ["can't be blank"] }]
    )

    it_behaves_like "jsonapi-resources__delete", Country, Country.model_name

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

    context 'Delete countries' do
      describe 'For ngo user' do
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

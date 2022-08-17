require 'rails_helper'

module V1
  describe 'Observation Filters', type: :request do
    describe 'Tree' do
      it 'Returns the filters\' tree' do
        get '/observation_filters_tree', headers: non_api_webuser_headers

        expect(status).to eql(200)
      end
    end

    describe 'csv' do
      let(:country) { create(:country, name: 'Country') }
      let(:country2) { create(:country, name: 'Country 2') }

      before do
        create_list(:observation, 3, country: country)
        create_list(:observation, 2, country: country2)
      end

      it 'returns csv file' do
        get '/observations-csv', headers: non_api_webuser_headers

        csv_rows = CSV.parse(response.body)

        expect(response.header['Content-Type']).to include('text/csv')
        expect(status).to eql(200)
        expect(csv_rows.count).to eq(3 + 2 + 1) # +1 because of header
      end

      context 'filters' do
        it 'returns filtered csv' do
          get "/observations-csv?filter[country_id]=#{country2.id}", headers: non_api_webuser_headers

          csv_rows = CSV.parse(response.body)

          expect(response.header['Content-Type']).to include('text/csv')
          expect(status).to eql(200)
          expect(csv_rows.count).to eq(2 + 1) # +1 because of header
        end
      end
    end
  end
end

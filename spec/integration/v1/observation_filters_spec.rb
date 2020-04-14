require 'rails_helper'

module V1
  describe 'Observation Filters', type: :request do
    describe 'Index' do
      it 'Returns results with no filtering' do
        get '/observation_filters', headers: non_api_webuser_headers

        expect(status).to eq(200)
      end
    end

    describe 'Tree' do
      it 'Returns the filters\' tree' do
        get '/observation_filters_tree', headers: non_api_webuser_headers

        expect(status).to eql(200)
      end
    end
  end
end

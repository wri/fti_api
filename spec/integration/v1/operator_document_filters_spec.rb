require 'rails_helper'

module V1
  describe 'Operator Document Filters', type: :request do
    describe 'Tree' do
      it 'Returns the filters\' tree' do
        get '/operator_document_filters_tree', headers: non_api_webuser_headers

        expect(status).to eql(200)
      end
      it 'has operators_id' do
        # TODO
        # Needs seeds with the use case whit active operator from diferent countries, some of them from not active countries
        # or restoring test database with staging/development real data to have some value
        active_country_ids = Country.active.pluck(:id)

        get '/operator_document_filters_tree', headers: non_api_webuser_headers

        expect(parsed_body[:operator_id].count == Operator.filter_by_country_ids(active_country_ids).active.count).to eql(true)
        expect(parsed_body[:operator_id].count <= Operator.active.count).to eql(true)
      end
    end
  end
end

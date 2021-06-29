require 'rails_helper'

module V1
  describe 'Operator Document Filters', type: :request do
    describe 'Tree' do
      before :all do
        country_1 = create(:country, name: 'Poland', iso: 'PL')
        country_2 = create(:country, name: 'Spain', iso: 'ES')
        operator_1 = create(:operator, country: country_1, fa_id: 'fa_id1', name: 'operator 1')
        operator_2 = create(:operator, country: country_1, fa_id: 'fa_id2', name: 'operator 2')
        operator_3 = create(:operator, country: country_2, fa_id: 'fa_id3', name: 'operator 3')

        fmu_1 = create(:fmu, country: country_1, forest_type: 1, name: 'fmu 1')
        fmu_2 = create(:fmu, country: country_1, forest_type: 2, name: 'fmu 2')
        fmu_3 = create(:fmu, country: country_2, forest_type: 1, name: 'fmu 3')

        create(:fmu_operator, operator: operator_1, fmu: fmu_1)
        create(:fmu_operator, operator: operator_2, fmu: fmu_2)
        create(:fmu_operator, operator: operator_3, fmu: fmu_3)
      end

      subject { get '/operator_document_filters_tree', headers: non_api_webuser_headers }

      it 'performs correctly' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'returns correct filter tree' do
        subject

        expect(response.body).to match_snapshot('v1/operator_document_filters_tree')
      end
    end
  end
end

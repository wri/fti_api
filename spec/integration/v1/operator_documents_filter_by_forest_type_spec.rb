require 'rails_helper'

module V1

    describe 'OperatorDocumentsFilterByForestType', type: :request do

        let!(:operator_documents) { FactoryBot.create_list(:operator_document_fmu, 20)}
        let(:forest_type_id) { 1 }
        let(:operator_documents_url_with_included_and_filter_by_forest_type) {
            operator_documents_url + '?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document&filter[forest_types]='
        }

        describe 'GET all OperatorDocuments filtered by forest_types' do
            it 'is successful' do
                get(operator_documents_url_with_included_and_filter_by_forest_type + forest_type_id.to_s, headers: admin_headers)
                
                expect(status).to eql(200)
            end
            it 'returns only filtered' do
                records_count = OperatorDocument.by_forest_types(forest_type_id).count
                get(operator_documents_url_with_included_and_filter_by_forest_type + forest_type_id.to_s, headers: admin_headers)
                
                expect(parsed_data.count).to eql(records_count)
                expect(parsed_body[:included].any?).to eql(true)
            end
            it 'works with more than one forest_types' do
                records_count = OperatorDocument.by_forest_types(forest_type_id).count + OperatorDocument.by_forest_types(2).count
                get(operator_documents_url_with_included_and_filter_by_forest_type + 2.to_s + ',' + 1.to_s , headers: admin_headers)
                
                expect(parsed_data.count).to eql(records_count)
                expect(parsed_body[:included].any?).to eql(true)   
            end
        end
    end
end
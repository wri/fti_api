require 'rails_helper'

module V1

    describe 'OperatorDocuments', type: :request do

        let(:valid_params) { { 'locale' => 'en' } }
        let!(:operator_documents) { FactoryBot.create_list(:operator_document, 10)}
        let(:operator_documents_url_with_included) { '/operator-documents?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document'}
        
        describe 'GET all OperatorDocuments' do
            it 'is successful' do
                get('/operator-documents?locale=en', headers: admin_headers)
                expect(status).to eql(200)
            end
            it 'returns all' do
                get('/operator-documents?locale=en', headers: admin_headers)
                expect(operator_documents.count).to eql(10)
                expect(parsed_data.count).to eql(operator_documents.count)

            end
            it 'returns all with included' do
                get(operator_documents_url_with_included, headers: admin_headers)

                expect(parsed_data.count).to eql(operator_documents.count)
                expect(parsed_body[:included].any?).to eql(true)

            end
            it 'returns only provided OperatorDocuments' do
                operator_document_not_provided = FactoryBot.create(:operator_document)
                operator_document_not_provided.status = OperatorDocument.statuses[:doc_not_provided]
                operator_document_not_provided.save!
                get(operator_documents_url_with_included, headers: admin_headers)

                expect(parsed_data.count).to eql(operator_documents.count)
                expect(parsed_data.find { |item| item[:id] == operator_document_not_provided.id }).to be_nil
            end
        end
    end
end
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
            it 'returns OperatorDocuments status when admin' do
                operator_document_invalid = operator_documents.first
                operator_document_invalid.status = OperatorDocument.statuses[:doc_invalid]
                operator_document_invalid.save!

                get(operator_documents_url_with_included, headers: admin_headers)

                expect(parsed_data.count).to eql(operator_documents.count)
                expect(parsed_data.select { |item| item[:id] == operator_document_invalid.id.to_s and item[:attributes][:status] == 'doc_invalid' }.any?).to be true
            end

            it 'hides OperatorDocuments status when not admin' do
                operator_document_invalid = operator_documents.first
                operator_document_invalid.status = OperatorDocument.statuses[:doc_invalid]
                operator_document_invalid.save!

                get(operator_documents_url_with_included, headers: user_headers)

                expect(parsed_data.count).to eql(operator_documents.count)
                expect(parsed_data.select { |item| item[:id] == operator_document_invalid.id.to_s and item[:attributes][:status] == 'doc_not_provided' }.any?).to be true
            end
        end
    end
end

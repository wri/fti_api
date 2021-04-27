require 'rails_helper'

module V1

    describe 'OperatorDocumentsFilterByLegalCategory', type: :request do

        let!(:operator_documents) { FactoryBot.create_list(:operator_document, 10)}

        let!(:other_required_operator_document_group) { FactoryBot.create(:required_operator_document_group) }
        let!(:other_required_operator_document) { FactoryBot.create(
            :required_operator_document,
            required_operator_document_group: other_required_operator_document_group
            )
        }

        let!(:other_operator_documents) { FactoryBot.create(
            :operator_document,
            required_operator_document: other_required_operator_document
            )
        }

        let(:operator_documents_url_with_included_and_filter_by_legal_categories) {
            operator_documents_url + '?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document&filter[legal_categories]='
        }

        describe 'GET all OperatorDocuments filtered by legal category id' do
            it 'is successful' do
                get(operator_documents_url_with_included_and_filter_by_legal_categories + other_required_operator_document_group.id.to_s, headers: admin_headers)
                
                expect(status).to eql(200)
            end
            it 'returns only filtered' do
                get(operator_documents_url_with_included_and_filter_by_legal_categories + other_required_operator_document_group.id.to_s, headers: admin_headers)
                
                expect(parsed_data.count).to eql(1)
                expect(parsed_body[:included].any?).to eql(true)
            end
            it 'works with more than one legal category' do
                required_operator_document_group_id = operator_documents.first.required_operator_document.required_operator_document_group.id
                cranky_url = operator_documents_url_with_included_and_filter_by_legal_categories + other_required_operator_document_group.id.to_s + ','  + required_operator_document_group_id.to_s
                records_count = 1 + OperatorDocument.by_required_operator_document_group(required_operator_document_group_id).count
                get(cranky_url , headers: admin_headers)
                
                expect(parsed_data.count).to eql(records_count)
                expect(parsed_body[:included].any?).to eql(true)   
            end
        end
    end
end
require 'rails_helper'

module V1

  describe 'OperatorDocumentsFilterByCountry', type: :request do

    let!(:operator_documents) { create_list(:operator_document, 10)}

    let!(:other_operator_documents) {
      create(
        :operator_document,
        source: 2
      )
    }

    let(:valid_params) {
      {
        'locale' => 'en',
        'include' => 'operator,operator.country,fmu,operator-document-annexes,required-operator-document',
        'filter[country_ids]' => nil
      }
    }
    let(:operator_documents_url_with_included_and_filter_by_source_id) {
      operator_documents_url + '?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document&filter[source]='
    }

    describe 'GET all OperatorDocuments filtered by source id' do
      it 'is successful' do
        get(operator_documents_url_with_included_and_filter_by_source_id + 2.to_s, headers: admin_headers)
        expect(status).to eql(200)
      end
      it 'returns only filtered' do
        get(operator_documents_url_with_included_and_filter_by_source_id + 2.to_s, headers: admin_headers)
        expect(parsed_data.count).to eql(1)
        expect(parsed_body[:included].any?).to eql(true)
      end
      it 'works with more than one source' do
        get(operator_documents_url_with_included_and_filter_by_source_id + 2.to_s + ',' + 1.to_s , headers: admin_headers)
        expect(parsed_data.count).to eql(11)
        expect(parsed_body[:included].any?).to eql(true)
      end
    end
  end
end

require 'rails_helper'

module V1
  describe 'OperatorDocuments', type: :request do
    let(:valid_params) { { 'locale' => 'en' } }
    let(:operator_documents_url_with_included) { '/operator-documents?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document'}

    before :all do
      @signature_group = create(:required_operator_document_group, name: 'Publication Authorization')
      country = create(:country)
      # below generates one document
      @signature_document = create(:required_operator_document_country, required_operator_document_group: @signature_group, contract_signature: true, country: country)
      operator = create(:operator, country: country, fa_id: 'fa_id')
      document_group = create(:required_operator_document_group, name: 'Some group')
      # below creates 7 country documents for operator
      create_list(:required_operator_document_country, 7, required_operator_document_group: document_group, country: country)
      @doc_invalid = create(:operator_document_fmu)
      @doc_valid_private = create(
        :operator_document_fmu,
        start_date: 10.days.ago,
        expire_date: 10.days.from_now,
        response_date: 10.days.ago,
        public: false,
        note: 'notes'
      )
      @doc_invalid.update(status: 'doc_invalid')
      @doc_valid_private.update(status: 'doc_valid')
    end

    describe 'GET all OperatorDocuments' do
      it 'is successful' do
        get('/operator-documents?locale=en', headers: admin_headers)
        expect(status).to eql(200)
      end
      it 'returns all' do
        get('/operator-documents?locale=en', headers: admin_headers)
        expect(parsed_data.count).to eql(10)
      end
      it 'returns all with included' do
        get(operator_documents_url_with_included, headers: admin_headers)

        expect(parsed_data.count).to eql(10)
        expect(parsed_body[:included].any?).to eql(true)
      end

      context 'when admin' do
        it 'returns OperatorDocuments normal status' do
          get(operator_documents_url_with_included, headers: admin_headers)

          returned_document = parsed_data.find { |d| d[:id] == @doc_invalid.id.to_s }[:attributes]

          expect(parsed_data.count).to eql(10)
          expect(returned_document[:status]).to eq('doc_invalid')
        end
      end

      context 'when not admin' do
        it 'hides OperatorDocuments status' do
          get(operator_documents_url_with_included, headers: user_headers)

          returned_document = parsed_data.find { |d| d[:id] == @doc_invalid.id.to_s }[:attributes]

          expect(parsed_data.count).to eql(10)
          expect(returned_document[:status]).to eq('doc_not_provided')
        end

        context 'with signed publication authorization' do
          # approved is by default true (??? weird but no need to reset it back to true)
          before(:each) { @doc_valid_private.operator.update(approved: true) }

          it 'returns status if document not public' do
            get(operator_documents_url_with_included, headers: user_headers)

            returned_document = parsed_data.find { |d| d[:id] == @doc_valid_private.id.to_s }[:attributes]

            expect(parsed_data.count).to eql(10)
            expect(returned_document[:status]).to eq('doc_valid')
            expect(returned_document[:'start-date']).to eq(@doc_valid_private.start_date.to_s)
            expect(returned_document[:'expire-date']).to eq(@doc_valid_private.expire_date.to_s)
            expect(returned_document[:note]).to eq('notes')
            expect(returned_document[:'response-date']).to eq(@doc_valid_private.response_date.iso8601(3))
            expect(returned_document[:'updated-at']).not_to be_nil
            expect(returned_document[:'created-at']).not_to be_nil
          end
        end

        context 'with not signed publication authorization' do
          before(:each) { @doc_valid_private.operator.update(approved: false) }
          after(:each) { @doc_valid_private.operator.update(approved: true) }

          it 'returns not provided and hides attributes if document not public' do
            get(operator_documents_url_with_included, headers: user_headers)

            returned_document = parsed_data.find { |d| d[:id] == @doc_valid_private.id.to_s }[:attributes]
            expect(parsed_data.count).to eql(10)
            expect(returned_document[:status]).to eq('doc_not_provided')
            expect(returned_document[:'start-date']).to be_nil
            expect(returned_document[:'expire-date']).to be_nil
            expect(returned_document[:'response-date']).to be_nil
            expect(returned_document[:note]).to be_nil
            expect(returned_document[:'updated-at']).to be_nil
            expect(returned_document[:'created-at']).to be_nil
          end
        end
      end
    end
  end
end

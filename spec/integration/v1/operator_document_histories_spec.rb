require 'rails_helper'

module V1
  describe 'OperatorDocumentHistory', type: :request do
    context 'Wrong parameters' do
      let(:operator_document) { FactoryBot.create :operator_document_country }

      describe 'No filters' do
        it 'Fails with a descriptive message' do
          get('/operator-document-histories',
              headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql('Please add the date and operator-id filters')
        end
      end
      describe 'No date' do
        it 'Fails with a descriptive message' do
          get("/operator-document-histories?filter[operator-id]=#{operator_document.operator_id}",
              headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql('You must provide a date')
        end
      end
      describe 'No operator-id' do
        it 'Fails with a descriptive message' do
          get("/operator-document-histories?filter[date]=#{Date.today.to_s(:db)}",
              headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql('You must provide an operator-id')
        end
      end
      describe 'operator-id is not an integer' do
        it 'Fails with a descriptive message' do
          get("/operator-document-histories?filter[operator-id]=aa&filter[date]=#{Date.today.to_s(:db)}",
              headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql('Operator must be an integer')
        end
      end
      describe 'Invalid date' do
        it 'Fails with a descriptive message' do
          get("/operator-document-histories?filter[operator-id]=1&filter[date]=wrong-date",
              headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql('Invalid date format. Use: YYYY-MM-DD')
        end
      end

    end
    context 'Fetch History of changed document' do
      describe 'Modify operator document' do
        before do
          travel_to Time.local(2020, 10, 5, 0, 0, 0)
        end

        after do
          travel_back
        end
        let(:time1) { Time.local(2020, 10, 10, 0, 0, 0) }
        let(:time2) { Time.local(2020, 10, 15, 0, 0, 0) }
        let(:time3) { Time.local(2020, 10, 20, 0, 0, 0)}
        it 'Fetches the old state of the operator document' do
          operator_document = FactoryBot.create :operator_document_country
          attachment = operator_document.document_file.attachment_url
          travel_to time1
          operator_document.update(status: 'doc_valid')
          travel_to time2
          operator_document.update note: 'new note'
          travel_to time3
          operator_document.destroy

          search_time = (time1 + 2.day).to_date.to_s(:db)
          get("/operator-document-histories?filter[date]=#{search_time}&filter[operator-id]=#{operator_document.operator_id}",
              headers: admin_headers)
          expect(status).to eql(200)
          expect(first_parsed_attributes[:status]).to eql('doc_valid')
          expect(first_parsed_attributes[:attachment][:url]).to eql(attachment)
        end

        it 'Fetches the current state of the operator document' do
          operator_document = FactoryBot.create :operator_document_country
          attachment = operator_document.document_file.attachment_url
          travel_to time1
          operator_document.update(status: 'doc_invalid')
          travel_to time2
          operator_document.update note: 'new note'
          travel_to time3
          operator_document.update(status: 'doc_valid')

          search_time = (time3).to_date.to_s(:db)
          get("/operator-document-histories?filter[date]=#{search_time}&filter[operator-id]=#{operator_document.operator_id}",
              headers: admin_headers)
          expect(status).to eql(200)
          expect(first_parsed_attributes[:status]).to eql('doc_valid')
          expect(first_parsed_attributes[:attachment][:url]).to eql(attachment)
        end

        it 'Fetches only one history per operator document' do
          operator_document = FactoryBot.create :operator_document_country
          other_operator_document = FactoryBot.create :operator_document_country, operator_id: operator_document.operator_id
          attachment = operator_document.document_file.attachment_url
          travel_to time1
          operator_document.update(status: 'doc_invalid')
          travel_to time2
          operator_document.update note: 'new note'
          travel_to time3
          operator_document.update(status: 'doc_valid')

          search_time = (time3).to_date.to_s(:db)
          get("/operator-document-histories?filter[date]=#{search_time}&filter[operator-id]=#{operator_document.operator_id}",
              headers: admin_headers)  
          expect(status).to eql(200)
          expect(extract_operator_document_id.include?(operator_document.id)).to eql(true)
          expect(extract_operator_document_id.count(operator_document.id)).to eql(1)
        end
      end
    end
  end
end

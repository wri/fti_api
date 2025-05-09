require "rails_helper"

module V1
  describe "OperatorDocumentHistory", type: :request do
    context "Wrong parameters" do
      let(:operator_document) { FactoryBot.create :operator_document_country }

      describe "No filters" do
        it "Fails with a descriptive message" do
          get("/operator-document-histories",
            headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql("Please add the date and operator-id filters")
        end
      end
      describe "No date" do
        it "Fails with a descriptive message" do
          get("/operator-document-histories?filter[operator-id]=#{operator_document.operator_id}",
            headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql("You must provide a date")
        end
      end
      describe "No operator-id" do
        it "Fails with a descriptive message" do
          get("/operator-document-histories?filter[date]=#{Time.zone.today.to_fs(:db)}",
            headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql("You must provide an operator-id")
        end
      end
      describe "operator-id is not an integer" do
        it "Fails with a descriptive message" do
          get("/operator-document-histories?filter[operator-id]=aa&filter[date]=#{Time.zone.today.to_fs(:db)}",
            headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql("Operator must be an integer")
        end
      end
      describe "Invalid date" do
        it "Fails with a descriptive message" do
          get("/operator-document-histories?filter[operator-id]=1&filter[date]=wrong-date",
            headers: admin_headers)
          expect(status).to eql(400)
          expect(parsed_error).to eql("Invalid date format. Use: YYYY-MM-DD")
        end
      end
    end
    context "Fetch History of changed document" do
      describe "Modify operator document" do
        before do
          travel_to Time.zone.local(2020, 10, 5, 0, 0, 0)
        end

        after do
          travel_back
        end
        let(:time1) { Time.zone.local(2020, 10, 10, 0, 0, 0) }
        let(:time2) { Time.zone.local(2020, 10, 15, 0, 0, 0) }
        let(:time3) { Time.zone.local(2020, 10, 20, 0, 0, 0) }
        it "Fetches the old state of the operator document" do
          operator_document = FactoryBot.create :operator_document_country
          attachment = operator_document.document_file.attachment_url
          travel_to time1
          operator_document.update(status: "doc_valid")
          travel_to time2
          operator_document.update note: "new note"
          travel_to time3
          operator_document.destroy

          search_time = (time1 + 2.days).to_date.to_fs(:db)
          get("/operator-document-histories?filter[date]=#{search_time}&filter[operator-id]=#{operator_document.operator_id}",
            headers: admin_headers)

          expect(status).to eql(200)
          expect(first_parsed_attributes[:status]).to eql("doc_valid")
          expect(first_parsed_attributes[:attachment][:url]).to eql(attachment)
        end

        it "Fetches the current state of the operator document" do
          operator_document = FactoryBot.create :operator_document_country
          attachment = operator_document.document_file.attachment_url
          travel_to time1
          operator_document.update(status: "doc_invalid", admin_comment: "invalid")
          travel_to time2
          operator_document.update note: "new note"
          travel_to time3
          operator_document.update(status: "doc_valid")

          search_time = time3.to_date.to_fs(:db)
          get("/operator-document-histories?filter[date]=#{search_time}&filter[operator-id]=#{operator_document.operator_id}",
            headers: admin_headers)
          expect(status).to eql(200)
          expect(first_parsed_attributes[:status]).to eql("doc_valid")
          expect(first_parsed_attributes[:attachment][:url]).to eql(attachment)
        end

        it "Fetches only one history per operator document" do
          operator_document = FactoryBot.create :operator_document_country
          FactoryBot.create :operator_document_country, operator_id: operator_document.operator_id
          operator_document.document_file.attachment_url
          travel_to time1
          operator_document.update(status: "doc_invalid", admin_comment: "invalid")
          travel_to time2
          operator_document.update note: "new note"
          travel_to time3
          operator_document.update(status: "doc_valid")

          search_time = time3.to_date.to_fs(:db)
          get("/operator-document-histories?filter[date]=#{search_time}&filter[operator-id]=#{operator_document.operator_id}",
            headers: admin_headers)
          expect(status).to eql(200)
          expect(extract_operator_document_id.include?(operator_document.id)).to eql(true)
          expect(extract_operator_document_id.count(operator_document.id)).to eql(1)
        end
      end
    end

    context "hide or change status" do
      before :all do
        @operator = create(:operator)
        @doc_invalid = create(:operator_document, operator: @operator)
        @doc_valid_private = create(
          :operator_document,
          operator: @operator,
          start_date: 10.days.ago,
          expire_date: 10.days.from_now,
          response_date: 10.days.ago,
          public: false,
          note: "notes"
        )
        @doc_invalid.update!(status: "doc_invalid", admin_comment: "invalid")
        @doc_valid_private.update!(status: "doc_valid")
      end

      context "when admin" do
        subject do
          get("/operator-document-histories?filter[date]=#{Time.zone.today}&filter[operator-id]=#{@operator.id}", headers: admin_headers)
        end

        it "returns provided status" do
          subject

          returned_document = parsed_data.find { |d| d[:attributes][:"operator-document-id"] == @doc_invalid.id }[:attributes]

          expect(parsed_data.count).to eql(2)
          expect(returned_document[:status]).to eq("doc_invalid")
          expect(returned_document[:attachment]).to eq({url: @doc_invalid.document_file.attachment.url})
        end
      end

      context "when not admin" do
        subject do
          get("/operator-document-histories?filter[date]=#{Time.zone.today}&filter[operator-id]=#{@operator.id}", headers: user_headers)
        end

        it "hides OperatorDocuments status" do
          subject

          returned_document = parsed_data.find { |d| d[:attributes][:"operator-document-id"] == @doc_invalid.id }[:attributes]

          expect(parsed_data.count).to eql(2)
          expect(returned_document[:status]).to eq("doc_not_provided")
          expect(returned_document[:"admin-comment"]).to be_nil
          expect(returned_document[:attachment]).to eq({url: nil})
        end

        context "with signed publication authorization" do
          # approved is by default true (??? weird but no need to reset it back to true)
          before(:each) { @doc_valid_private.operator.update(approved: true) }

          it "returns status if document not public" do
            subject

            returned_document = parsed_data.find { |d| d[:attributes][:"operator-document-id"] == @doc_valid_private.id }[:attributes]

            expect(parsed_data.count).to eql(2)
            expect(returned_document[:status]).to eq("doc_valid")
            expect(returned_document[:"start-date"]).to eq(@doc_valid_private.start_date.to_s)
            expect(returned_document[:"expire-date"]).to eq(@doc_valid_private.expire_date.to_s)
            expect(returned_document[:note]).to eq("notes")
            expect(returned_document[:"response-date"]).to eq(@doc_valid_private.response_date.iso8601(3))
            expect(returned_document[:"updated-at"]).not_to be_nil
            expect(returned_document[:"created-at"]).not_to be_nil
            expect(returned_document[:attachment]).to eq({url: @doc_valid_private.document_file.attachment.url})

            invalid_doc = parsed_data.find { |d| d[:attributes][:"operator-document-id"] == @doc_invalid.id }[:attributes]
            expect(invalid_doc[:status]).to eq("doc_not_provided")
            expect(invalid_doc[:"admin-comment"]).to be_nil
            expect(invalid_doc[:attachment]).to eq({url: nil})
          end
        end

        context "with not signed publication authorization" do
          before(:each) { @doc_valid_private.operator.update(approved: false) }
          after(:each) { @doc_valid_private.operator.update(approved: true) }

          it "returns not provided and hides attributes if document not public" do
            subject

            returned_document = parsed_data.find { |d| d[:attributes][:"operator-document-id"] == @doc_valid_private.id }[:attributes]
            expect(parsed_data.count).to eql(2)
            expect(returned_document[:status]).to eq("doc_not_provided")
            expect(returned_document[:attachment]).to eq({url: nil})
            expect(returned_document[:"start-date"]).to be_nil
            expect(returned_document[:"expire-date"]).to be_nil
            expect(returned_document[:"response-date"]).to be_nil
            expect(returned_document[:note]).to be_nil
            expect(returned_document[:"updated-at"]).to be_nil
            expect(returned_document[:"created-at"]).to be_nil

            invalid_doc = parsed_data.find { |d| d[:attributes][:"operator-document-id"] == @doc_invalid.id }[:attributes]
            expect(invalid_doc[:status]).to eq("doc_not_provided")
            expect(invalid_doc[:"admin-comment"]).to be_nil
            expect(invalid_doc[:attachment]).to eq({url: nil})
          end
        end
      end
    end
  end
end

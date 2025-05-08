require "rails_helper"

module V1
  describe "OperatorDocuments", type: :request do
    let(:valid_params) { {"locale" => "en"} }
    let(:operator_documents_url_with_included) { "/operator-documents?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document" }

    before :all do
      @signature_group = create(:required_operator_document_group, name: "Publication Authorization")
      country = create(:country)
      # below generates one document
      create(:required_operator_document_country, required_operator_document_group: @signature_group, contract_signature: true, country: country)
      @operator = create(:operator, country: country, fa_id: "fa_id", approved: false)
      document_group = create(:required_operator_document_group, name: "Some group")
      # below creates 7 country documents for operator
      create_list(:required_operator_document_country, 7, required_operator_document_group: document_group, country: country)
      @doc_invalid = create(:operator_document_fmu, operator: @operator)
      @doc_valid_private = create(
        :operator_document_fmu,
        operator: @operator,
        start_date: 10.days.ago,
        expire_date: 10.days.from_now,
        response_date: 10.days.ago,
        public: false,
        note: "notes"
      )
      @doc_invalid.update!(status: "doc_invalid", admin_comment: "invalid")
      @doc_valid_private.update!(status: "doc_valid")
      @signature_document = @operator.reload.operator_documents.signature.first # not sure why need to reload operator
    end

    def sign_publication_authorization!
      @signature_document.update!(
        document_file: create(:document_file),
        start_date: Time.zone.today,
        expire_date: 1.year.from_now,
        status: "doc_valid"
      )
    end

    describe "GET OperatorDocuments" do
      it "is successful" do
        get("/operator-documents?locale=en", headers: admin_headers)
        expect(status).to eql(200)
      end
      it "returns all" do
        get("/operator-documents?locale=en", headers: admin_headers)
        expect(parsed_data.count).to eql(10)
      end
      it "returns all with included" do
        get(operator_documents_url_with_included, headers: admin_headers)

        expect(parsed_data.count).to eql(10)
        expect(parsed_body[:included].any?).to eql(true)
      end

      context "when admin" do
        it "returns OperatorDocuments normal status" do
          get(operator_documents_url_with_included, headers: admin_headers)

          returned_document = parsed_data.find { |d| d[:id] == @doc_invalid.id.to_s }[:attributes]

          expect(parsed_data.count).to eql(10)
          expect(returned_document[:status]).to eq("doc_invalid")
          expect(returned_document[:"admin-comment"]).to eq("invalid")
        end

        it "returns publication authorization" do
          get(operator_documents_url_with_included, headers: admin_headers)

          returned_document = parsed_data.find { |d| d[:id] == @signature_document.id.to_s }[:attributes]

          expect(returned_document[:status]).to eq("doc_not_provided")
        end
      end

      context "when not admin" do
        it "does not return publication authorization" do
          get(operator_documents_url_with_included, headers: user_headers)

          returned_document = parsed_data.find { |d| d[:id] == @signature_document.id.to_s }

          expect(returned_document).to be_nil
        end

        it "hides OperatorDocuments status" do
          get(operator_documents_url_with_included, headers: user_headers)

          returned_document = parsed_data.find { |d| d[:id] == @doc_invalid.id.to_s }[:attributes]

          expect(parsed_data.count).to eql(9)
          expect(returned_document[:status]).to eq("doc_not_provided")
          expect(returned_document[:"admin-comment"]).to be_nil
        end

        context "with signed publication authorization" do
          # approved is by default true (??? weird but no need to reset it back to true)
          before(:each) { sign_publication_authorization! }

          it "returns status if document not public" do
            get(operator_documents_url_with_included, headers: user_headers)

            returned_document = parsed_data.find { |d| d[:id] == @doc_valid_private.id.to_s }[:attributes]

            expect(parsed_data.count).to eql(9)
            expect(returned_document[:status]).to eq("doc_valid")
            expect(returned_document[:"start-date"]).to eq(@doc_valid_private.start_date.to_s)
            expect(returned_document[:"expire-date"]).to eq(@doc_valid_private.expire_date.to_s)
            expect(returned_document[:note]).to eq("notes")
            expect(returned_document[:"response-date"]).to eq(@doc_valid_private.response_date.iso8601(3))
            expect(returned_document[:"updated-at"]).not_to be_nil
            expect(returned_document[:"created-at"]).not_to be_nil

            invalid_doc = parsed_data.find { |d| d[:id] == @doc_invalid.id.to_s }[:attributes]
            expect(invalid_doc[:status]).to eq("doc_not_provided")
            expect(invalid_doc[:"admin-comment"]).to be_nil
          end
        end

        context "with not signed publication authorization" do
          it "returns not provided and hides attributes if document not public" do
            get(operator_documents_url_with_included, headers: user_headers)

            returned_document = parsed_data.find { |d| d[:id] == @doc_valid_private.id.to_s }[:attributes]
            expect(parsed_data.count).to eql(9)
            expect(returned_document[:status]).to eq("doc_not_provided")
            expect(returned_document[:"start-date"]).to be_nil
            expect(returned_document[:"expire-date"]).to be_nil
            expect(returned_document[:"response-date"]).to be_nil
            expect(returned_document[:note]).to be_nil
            expect(returned_document[:"updated-at"]).to be_nil
            expect(returned_document[:"created-at"]).to be_nil

            invalid_doc = parsed_data.find { |d| d[:id] == @doc_invalid.id.to_s }[:attributes]
            expect(invalid_doc[:status]).to eq("doc_not_provided")
            expect(invalid_doc[:"admin-comment"]).to be_nil
          end
        end
      end
    end
  end
end

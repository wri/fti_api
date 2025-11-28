require "rails_helper"

module V1
  describe "OperatorDocumentAnnex", type: :request do
    describe "json-api-resource" do
      let(:operator_document) { create(:operator_document_fmu) }
      let(:document_data) {
        "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, "spec", "support", "files", "doc.pdf")))}"
      }
      let(:operator_document_annex) {
        create(:operator_document_annex, user: operator_user, operator_document: operator_document, force_status: :doc_valid)
      }

      before { operator_user.update!(operator: operator_document.operator) }

      it_behaves_like "jsonapi-resources", OperatorDocumentAnnex, {
        show: {
          resource: -> { operator_document_annex }
        },
        create: {
          success_roles: %i[admin operator_user],
          failure_roles: %i[user webuser],
          valid_params: -> {
                          {
                            name: "Annex name",
                            "start-date": Time.zone.today.to_s,
                            attachment: document_data,
                            relationships: {"operator-document": operator_document.id}
                          }
                        },
          excluded_params: %i[attachment],
          invalid_params: {name: ""},
          error_attributes: [422, 100, {name: ["can't be blank"], "start-date": ["can't be blank"]}]
        },
        edit: {
          resource: -> { operator_document_annex },
          success_roles: %i[admin operator_user],
          failure_roles: %i[user webuser],
          valid_params: -> {
                          {
                            name: "New Annex name",
                            "start-date": Time.zone.today.to_s
                          }
                        },
          excluded_params: %i[attachment],
          invalid_params: {name: ""},
          error_attributes: [422, 100, {name: ["can't be blank"]}]
        },
        delete: {
          resource: -> { operator_document_annex },
          success_roles: %i[admin operator_user],
          failure_roles: %i[user webuser]
        },
        route_key: "operator-document-annexes"
      }
    end

    describe "GET OperatorDocumentAnnexes" do
      let(:operator_document) { create(:operator_document_fmu, operator: operator_user.operator) }
      let!(:valid_annex) { create(:operator_document_annex, operator_document: operator_document, force_status: :doc_valid) }
      let!(:history_annex) { create(:operator_document_annex, force_status: :doc_valid, operator_document_histories: [create(:operator_document_history, operator: operator_user.operator)]) }
      let!(:invalid_annex) { create(:operator_document_annex, operator_document: operator_document, force_status: :doc_invalid) }
      let!(:other_invalid_annex) { create(:operator_document_annex, force_status: :doc_invalid) }

      context "when admin" do
        it "returns all annexes" do
          get("/operator-document-annexes", headers: admin_headers)

          expect(parsed_data.count).to eql(4)
          valid_annex_data = parsed_data.find { |d| d[:id] == valid_annex.id.to_s }[:attributes]
          invalid_annex_data = parsed_data.find { |d| d[:id] == invalid_annex.id.to_s }[:attributes]
          other_annex_data = parsed_data.find { |d| d[:id] == other_invalid_annex.id.to_s }[:attributes]
          history_annex_data = parsed_data.find { |d| d[:id] == history_annex.id.to_s }[:attributes]

          expect(valid_annex_data[:status]).to eq("doc_valid")
          expect(valid_annex_data[:attachment]).to eq({url: valid_annex.attachment.url})
          expect(invalid_annex_data[:status]).to eq("doc_invalid")
          expect(invalid_annex_data[:attachment]).to eq({url: invalid_annex.attachment.url})
          expect(other_annex_data[:status]).to eq("doc_invalid")
          expect(other_annex_data[:attachment]).to eq({url: other_invalid_annex.attachment.url})
          expect(history_annex_data[:attachment]).to eq({url: history_annex.attachment.url})
          expect(history_annex_data[:status]).to eq("doc_valid")
        end
      end

      context "when operator" do
        it "returns all operator annexes" do
          get("/operator-document-annexes", headers: operator_user_headers)

          expect(parsed_data.count).to eql(3)
          valid_annex_data = parsed_data.find { |d| d[:id] == valid_annex.id.to_s }[:attributes]
          invalid_annex_data = parsed_data.find { |d| d[:id] == invalid_annex.id.to_s }[:attributes]
          history_annex_data = parsed_data.find { |d| d[:id] == history_annex.id.to_s }[:attributes]

          expect(valid_annex_data[:status]).to eq("doc_valid")
          expect(valid_annex_data[:attachment]).to eq({url: valid_annex.attachment.url})
          expect(invalid_annex_data[:status]).to eq("doc_invalid")
          expect(invalid_annex_data[:attachment]).to eq({url: invalid_annex.attachment.url})
          expect(history_annex_data[:attachment]).to eq({url: history_annex.attachment.url})
          expect(history_annex_data[:status]).to eq("doc_valid")
        end
      end

      context "when public user" do
        it "returns valid annexes" do
          get("/operator-document-annexes", headers: webuser_headers)

          expect(parsed_data.count).to eql(2)
          valid_annex_data = parsed_data.find { |d| d[:id] == valid_annex.id.to_s }[:attributes]
          invalid_annex_data = parsed_data.find { |d| d[:id] == invalid_annex.id.to_s }
          history_annex_data = parsed_data.find { |d| d[:id] == history_annex.id.to_s }[:attributes]

          expect(valid_annex_data[:status]).to eq("doc_valid")
          expect(valid_annex_data[:attachment]).to eq({url: valid_annex.attachment.url})
          expect(invalid_annex_data).to be_nil
          expect(history_annex_data[:attachment]).to eq({url: history_annex.attachment.url})
          expect(history_annex_data[:status]).to eq("doc_valid")
        end
      end
    end
  end
end

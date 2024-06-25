require "rails_helper"

module V1
  describe "OperatorDocumentAnnex", type: :request do
    let(:operator_document) { create(:operator_document_fmu) }
    let(:document_data) {
      "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, "spec", "support", "files", "doc.pdf")))}"
    }
    let(:operator_document_annex) {
      create(:operator_document_annex, user: operator_user, operator_document: operator_document)
    }

    before { operator_user.update!(operator: operator_document.operator) }

    it_behaves_like "jsonapi-resources", OperatorDocumentAnnex, {
      show: {},
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
end

require "rails_helper"

module V1
  describe "Observation Documents", type: :request do
    let(:user) { create(:user) }
    let(:observation_report) { create(:observation_report) }

    # TODO: add attachment
    let(:document_data) {
      "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, "spec", "support", "files", "doc.pdf")))}"
    }

    it_behaves_like "jsonapi-resources", ObservationDocument, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: -> { {name: "Document one", attachment: document_data, relationships: {user: user.id, observation_report: observation_report.id}} },
        excluded_params: %i[attachment] # workaround as after upload attachment is url and not base64
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: {name: "Document one"}
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :name,
        sequence: ->(i) { "#{i} document name" }
      },
      route_key: "observation-documents"
    }
  end
end

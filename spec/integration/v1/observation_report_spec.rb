require "rails_helper"

module V1
  describe "Observation Reports", type: :request do
    let(:user) { create(:user) }
    let(:document_data) {
      "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, "spec", "support", "files", "doc.pdf")))}"
    }
    let(:observer) { create(:observer) }

    it_behaves_like "jsonapi-resources", ObservationReport, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: -> {
          {
            title: "Report one",
            "publication-date": Time.zone.today.to_s,
            attachment: document_data,
            relationships: {user: user.id, observers: [observer.id]}
          }
        },
        excluded_params: %i[attachment publication-date] # workaround as comparing publication-date does not work
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: {title: "Report one"}
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :title,
        sequence: ->(i) { "#{i} report name" }
      },
      route_key: "observation-reports"
    }
  end
end

require "rails_helper"

module V1
  describe "Severities", type: :request do
    it_behaves_like "jsonapi-resources", Severity, {
      show: {
        success_roles: %i[admin]
      },
      pagination: {
        success_roles: %i[admin]
      },
      sort: {
        success_roles: %i[admin],
        attribute: :details,
        sequence: ->(i) { "Details #{i}" }
      },
      filter: {
        success_roles: %i[admin],
        filters: [
          {expected_count: 1, attributes: {subcategory_id: FactoryBot.create(:subcategory).id}}
        ]
      }
    }
  end
end

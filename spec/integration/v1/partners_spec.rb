require "rails_helper"

module V1
  describe "Partners", type: :request do
    it_behaves_like "jsonapi-resources", Partner, {
      translations: {
        locales: [:en, :fr],
        attributes: {name: "Name", description: "Description"}
      },
      sort: {
        attribute: :priority,
        sequence: ->(i) { i }
      },
      route_key: "partners"
    }
  end
end

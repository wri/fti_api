require "rails_helper"

module V1
  describe "Tools", type: :request do
    it_behaves_like "jsonapi-resources", Tool, {
      translations: {
        locales: [:en, :fr],
        attributes: {name: "Name", description: "Description"}
      },
      sort: {
        attribute: :position,
        sequence: ->(i) { i }
      },
      route_key: "tools"
    }
  end
end

require "rails_helper"

module V1
  describe "Tutorials", type: :request do
    it_behaves_like "jsonapi-resources", Tutorial, {
      translations: {
        locales: [:en, :fr],
        attributes: {name: "Name", description: "Description"}
      },
      sort: {
        attribute: :position,
        sequence: ->(i) { i }
      },
      route_key: "tutorials"
    }
  end
end

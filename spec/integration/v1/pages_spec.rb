require "rails_helper"

module V1
  describe "Page", type: :request do
    it_behaves_like "jsonapi-resources", Page, {
      translations: {
        locales: [:en, :fr],
        attributes: {title: "Title", body: "Body"}
      },
      route_key: "pages"
    }
  end
end

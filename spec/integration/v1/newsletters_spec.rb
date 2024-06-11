require "rails_helper"

module V1
  describe "Newsletter", type: :request do
    it_behaves_like "jsonapi-resources", Newsletter, {
      translations: {
        locales: [:en, :fr],
        attributes: {title: "Title", short_description: "Lorem ipsum dolor"}
      },
      route_key: "newsletters"
    }
  end
end

require "rails_helper"

module V1
  describe "Faqs", type: :request do
    it_behaves_like "jsonapi-resources", Faq, {
      translations: {
        locales: [:en, :fr],
        attributes: {question: "FAQ Question", answer: "Answer"}
      },
      route_key: "faqs"
    }
  end
end

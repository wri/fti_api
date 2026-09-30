require "rails_helper"

RSpec.describe OperatorDocumentFilterTree do
  describe "#tree" do
    it "translates labels to the current locale" do
      I18n.with_locale(:en) { described_class.new.tree }

      tree = I18n.with_locale(:fr) { described_class.new.tree }

      expect(tree[:status].find { it[:id] == "doc_valid" }[:name]).to eq(I18n.t("operator_documents.filters.doc_valid", locale: :fr))
      expect(tree[:source].first[:name]).to eq(I18n.t("filters.company", locale: :fr))
    end
  end
end

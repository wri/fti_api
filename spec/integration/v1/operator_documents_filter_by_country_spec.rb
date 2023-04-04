require "rails_helper"

module V1
  describe "OperatorDocumentsFilterByCountry", type: :request do
    let!(:operator_documents) { create_list(:operator_document, 10) }

    let!(:country) { create(:country) }
    let!(:operator) { create(:operator, country: country, fa_id: "fa_id") }
    let!(:required_operator_document_group) { create(:required_operator_document_group) }
    let!(:required_operator_document_same_country) {
      create_list(
        :required_operator_document_country, 5,
        country: country,
        required_operator_document_group: required_operator_document_group
      )
    }

    let!(:other_country) { create(:country) }
    let!(:other_operator) { create(:operator, country: other_country, fa_id: "fa_id") }
    let!(:other_required_operator_document_group) { create(:required_operator_document_group) }
    let!(:other_required_operator_document) {
      create(
        :required_operator_document_country,
        country: other_country,
        required_operator_document_group: other_required_operator_document_group
      )
    }

    let(:valid_params) {
      {
        "locale" => "en",
        "include" => "operator,operator.country,fmu,operator-document-annexes,required-operator-document",
        "filter[country_ids]" => nil
      }
    }
    let(:operator_documents_url_with_included_and_filter_by_country_ids) {
      operator_documents_url + "?locale=en&include=operator,operator.country,fmu,operator-document-annexes,required-operator-document&filter[country_ids]="
    }

    describe "GET all OperatorDocuments filtered by country id" do
      it "is successful" do
        get(operator_documents_url_with_included_and_filter_by_country_ids + country.id.to_s, headers: admin_headers)
        expect(status).to eql(200)
      end
      it "returns only filtered" do
        get(operator_documents_url_with_included_and_filter_by_country_ids + country.id.to_s, headers: admin_headers)
        expect(parsed_data.count).to eql(5)
        expect(parsed_body[:included].any?).to eql(true)
      end
      it "works with more than one country" do
        get(operator_documents_url_with_included_and_filter_by_country_ids + country.id.to_s + "," + other_country.id.to_s, headers: admin_headers)
        expect(parsed_data.count).to eql(6)
        expect(parsed_body[:included].any?).to eql(true)
      end
    end
  end
end

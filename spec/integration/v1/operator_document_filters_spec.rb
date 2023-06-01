require "rails_helper"

module V1
  describe "Operator Document Filters", type: :request do
    before :all do
      @country_1 = create(:country, name: "Poland", iso: "PL")
      @country_2 = create(:country, name: "Spain", iso: "ES")

      publication_group = create(:required_operator_document_group, name: "Publication Authorization")
      @group_2 = create(:required_operator_document_group, name: "Document Group 2")

      @pb_1 = create(:required_operator_document_country, name: "pub auth", country: @country_1, required_operator_document_group: publication_group)
      @pb_2 = create(:required_operator_document_country, name: "oub auth", country: @country_2, required_operator_document_group: publication_group)
      @rod_1 = create(:required_operator_document_fmu, name: "req SUPER doc1", country: @country_1, required_operator_document_group: @group_2, forest_types: [1, 2])
      @rod_2 = create(:required_operator_document_fmu, name: "req Doc2", country: @country_2, required_operator_document_group: @group_2, forest_types: [1, 2])

      @operator_1 = create(:operator, country: @country_1, fa_id: "fa_id1", name: "operator 1")
      @operator_2 = create(:operator, country: @country_1, fa_id: "fa_id2", name: "operator 2")
      @operator_3 = create(:operator, country: @country_2, fa_id: "fa_id3", name: "operator 3")

      @fmu_1 = create(:fmu, country: @country_1, forest_type: 1, name: "fmu 1")
      @fmu_2 = create(:fmu, country: @country_1, forest_type: 2, name: "fmu 2")
      @fmu_3 = create(:fmu, country: @country_2, forest_type: 1, name: "fmu 3")

      create(:fmu_operator, operator: @operator_1, fmu: @fmu_1)
      create(:fmu_operator, operator: @operator_2, fmu: @fmu_2)
      create(:fmu_operator, operator: @operator_3, fmu: @fmu_3)

      get "/operator_document_filters_tree", headers: non_api_webuser_headers
    end

    # before :each do

    # end

    it "performs correctly" do
      expect(response).to have_http_status(:ok)
    end

    it "returns forest types" do
      expect(parsed_body[:forest_types]).to match_array(forest_types)
    end

    it "returns statuses" do
      expected_statuses_ids = %w[doc_not_provided doc_valid doc_expired doc_not_required]
      expect(parsed_body[:status].pluck(:id)).to match_array(expected_statuses_ids)
    end

    it "return sources" do
      expect(parsed_body[:source]).to eq([
        {id: 1, name: "Company"},
        {id: 2, name: "Forest Atlas"},
        {id: 3, name: "Others"}
      ])
    end

    it "returns operators" do
      expect(parsed_body[:operator_id]).to eq([{
        id: @operator_1.id,
        name: @operator_1.name,
        fmus: [@fmu_1.id],
        forest_types: [
          forest_type_entry(:ufa)
        ]
      }, {
        id: @operator_2.id,
        name: @operator_2.name,
        fmus: [@fmu_2.id],
        forest_types: [
          forest_type_entry(:cf)
        ]
      }, {
        id: @operator_3.id,
        name: @operator_3.name,
        fmus: [@fmu_3.id],
        forest_types: [
          forest_type_entry(:ufa)
        ]
      }])
    end

    it "returns countries" do
      expect(parsed_body[:country_ids]).to eq([{
        id: @country_1.id,
        iso: @country_1.iso,
        name: @country_1.name,
        fmus: [@fmu_1.id, @fmu_2.id],
        operators: [
          @operator_1.id,
          @operator_2.id
        ],
        forest_types: [
          forest_type_entry(:ufa),
          forest_type_entry(:cf)
        ],
        required_operator_document_ids: [
          @rod_1.id
        ]
      }, {
        id: @country_2.id,
        iso: @country_2.iso,
        name: @country_2.name,
        fmus: [@fmu_3.id],
        operators: [
          @operator_3.id
        ],
        forest_types: [
          forest_type_entry(:ufa)
        ],
        required_operator_document_ids: [
          @rod_2.id
        ]
      }])
    end

    it "returns fmus" do
      expect(parsed_body[:fmu_id]).to match_array(Fmu.with_translations.map { |f| f.slice(:id, :name).symbolize_keys.to_h })
    end

    it "returns required operator documents" do
      expect(parsed_body[:required_operator_document_id]).to eq([{
        id: @rod_1.id, name: "Req SUPER doc1"
      }, {
        id: @rod_2.id, name: "Req doc2"
      }])
    end

    it "does not return publication authorization document group" do
      expect(parsed_body[:required_operator_document_id].pluck(:id)).not_to include(@pb_1.id)
      expect(parsed_body[:required_operator_document_id].pluck(:id)).not_to include(@pb_2.id)
    end

    it "returns legal categories" do
      expect(parsed_body[:legal_categories]).to eq([{
        id: @group_2.id,
        name: @group_2.name,
        required_operator_document_ids: [
          @rod_1.id,
          @rod_2.id
        ]
      }])
    end

    def forest_types
      ForestType::TYPES.map do |key, _value|
        forest_type_entry(key)
      end
    end

    def forest_type_entry(key)
      value = ForestType::TYPES[key]
      {key: key.to_s, id: value[:index], name: value[:label]}
    end
  end
end

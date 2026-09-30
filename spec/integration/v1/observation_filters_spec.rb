require "rails_helper"

module V1
  describe "Observation Filters", type: :request do
    let(:country) { create(:country, name: "Country") }
    let(:country2) { create(:country, name: "Country 2") }

    before do
      create_list(:observation, 3, country: country)
      create_list(:observation, 2, country: country2)
      create(:gov_observation)
      create_list(:observation_report, 2)
    end

    describe "Tree" do
      it "Returns the filters' tree" do
        get "/observation_filters_tree"

        expect(status).to eql(200)
      end

      it "sorts observation reports by title" do
        create(:observation, observation_report: create(:observation_report, title: "B report"))
        create(:observation, observation_report: create(:observation_report, title: "A report"))

        get "/observation_filters_tree"

        names = parsed_body[:"observation-report"].pluck(:name)
        expect(names).to eq(names.sort)
      end
    end
  end
end

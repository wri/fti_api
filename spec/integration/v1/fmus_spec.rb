require "rails_helper"

module V1
  describe "Fmus", type: :request do
    it_behaves_like "jsonapi-resources", Fmu, {
      show: {
        success_roles: %i[admin]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[ngo],
        valid_params: {name: "Example fmu"},
        invalid_params: {name: nil},
        error_attributes: [422, 100, {name: ["can't be blank"]}]
      }
    }

    describe "Show" do
      let!(:fmu) { create(:fmu_geojson) }

      it "Is available without authentication" do
        get "/fmus/#{fmu.id}"

        expect(status).to eq(200)
        expect(JSON.parse(response.body)["data"]["id"]).to eq(fmu.id.to_s)
      end

      it "Returns a feature collection when format=geojson" do
        get "/fmus/#{fmu.id}?format=geojson"

        expect(status).to eq(200)
        json = JSON.parse(response.body)
        expect(json["type"]).to eq("FeatureCollection")
        expect(json["features"].count).to eq(1)
        expect(json["features"].first.dig("properties", "id")).to eq(fmu.id)
      end

      it "Returns 404 for an unknown fmu" do
        get "/fmus/0"

        expect(status).to eq(404)
      end
    end
  end
end

require "rails_helper"
require "rspec_api_documentation/dsl"

resource "Protected Areas" do
  explanation "Protected areas resource"

  let!(:protected_area) { FactoryBot.create(:protected_area) }

  get "/protected_areas/tiles/:z/:x/:y" do
    route_summary "Fetches the vector tiles"
    route_description "It gets the vector tiles for the provided Z index and coordinates"

    parameter :z, "Z index", in: "path",
      type: :integer, with_example: true, default: 6, minimum: 0
    parameter :x, "X coordinate", in: "path",
      type: :integer, with_example: true, default: 35, minimum: 0
    parameter :y, "Y coordinate", in: "path",
      type: :integer, with_example: true, default: 21, minimum: 0

    # z/x/y covering the factory polygon, so a swapped path segment yields a
    # different, empty tile and fails the body expectation below.
    let(:z) { 6 }
    let(:x) { 35 }
    let(:y) { 21 }

    context "200" do
      example_request "Getting tiles for a zoom level and coordinates" do
        expect(status).to eql 200
        expect(response_headers["Content-Type"]).to eql "application/vnd.mapbox-vector-tile"
        expect(response_body).not_to be_empty
      end
    end

    context "200 for a tile with no data" do
      let(:x) { 0 }

      example_request "Getting an empty tile" do
        expect(status).to eql 200
        expect(response_body).to be_empty
      end
    end
  end
end

require "rails_helper"
require "rspec_api_documentation/dsl"

resource "Fmus" do
  explanation "FMUs resource"

  header "Content-Type", "application/vnd.api+json"

  let(:country) { FactoryBot.create(:country) }
  let!(:operator) { FactoryBot.create(:operator, country: country) }
  let!(:fmus) { FactoryBot.create_list(:fmu, 5, {country: country, operator: operator}) }

  get "/fmus" do
    route_summary "Lists all the fmus"
    route_description 'It fetches all the fmus.
If the parameter format=geojson is provided, the fmus will come in the geojson format and all the other parameters will be ignored.
If not, then the request is processed as a typical JSON API request.'

    add_include_parameter example: %w[country operator]
    add_filter_parameters_for V1::FmuResource
    add_field_parameter_for :fmu
    add_paging_parameters
    add_sort_parameter

    let(:observer) { create(:observer) }
    let(:fmu_with_obs) { create(:fmu, country: country) }

    before do
      create(:fmu_operator, fmu: fmu_with_obs, operator: operator)
      create(:observation, operator: operator, fmu: fmu_with_obs, observation_report: create(:observation_report, observers: [observer]))
    end

    context "200" do
      example_request "Listing fmus" do
        expect(status).to eq 200
        expect(JSON.parse(response_body)["data"].count).to eql(fmus.count + 1)
      end

      example "Filter by observer id", document: false do
        do_request "filter[observer_id]": observer.id

        parsed_data = JSON.parse(response_body)["data"]

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(1)
        expect(parsed_data.first["id"].to_i).to eq(fmu_with_obs.id)
      end
    end
  end

  get "/fmus/:id" do
    route_summary "Fetches a fmu by id"
    route_description 'It fetches a fmu by id.
If the parameter format=geojson is provided, the fmu will come in the geojson format.
If not, then the request is processed as a typical JSON API request.'

    parameter :id, "id", in: :path, type: :integer
    add_include_parameter example: %w[country operator]
    add_field_parameter_for :fmu

    let(:id) { fmus.first.id }

    context "200" do
      example_request "Get one fmu" do
        expect(status).to eql 200
        expect(JSON.parse(response_body)["data"]["id"]).to eql(id.to_s)
      end
    end

    context "404" do
      let(:id) { 1000 }
      example_request "Fmu not found" do
        expect(status).to eql 404
      end
    end
  end

  get "fmus?format=geojson" do
    route_summary "Lists all the fmus in geojson format"
    route_description "All the fmus retrieved in the geojson format"

    context "200" do
      example_request "Listing fmus in geojson" do
        expect(status).to eql 200
      end
    end
  end

  get "/fmus/tiles/:z/:x/:y" do
    route_summary "Fetches the vector tiles"
    route_description "It gets the vector tiles for the provided Z index and coordinates"

    parameter :z, "Z index", in: "path",
      type: :integer, with_example: true, default: 6, minimum: 0
    parameter :x, "X coordinate", in: "path",
      type: :integer, with_example: true, default: 34, minimum: 0
    parameter :y, "Y coordinate", in: "path",
      type: :integer, with_example: true, default: 32, minimum: 0
    parameter :operator_id, "Operator Id", in: "query", type: :integer

    # z/x/y covering the :geojson trait polygon, so a swapped path segment
    # yields a different, empty tile and fails the body expectation below.
    let(:z) { 6 }
    let(:x) { 34 }
    let(:y) { 32 }
    let!(:fmu_with_geometry) { create(:fmu, :geojson, country: country, operator: operator) }

    context "200" do
      example_request "Getting tiles for a zoom level and coordinates" do
        expect(status).to eql 200
        expect(response_headers["Content-Type"]).to eql "application/vnd.mapbox-vector-tile"
        expect(response_body).not_to be_empty
      end
    end

    context "200 with an operator filter" do
      let(:operator_id) { operator.id }

      example_request "Getting tiles for a single operator" do
        expect(status).to eql 200
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

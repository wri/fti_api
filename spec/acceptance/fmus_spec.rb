require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Fmus' do
  explanation "FMUs resource"

  let!(:web_user) { FactoryBot.create(:admin) }
  let!(:web_token) { 'Bearer ' + web_user.api_key.access_token }

  let!(:admin) { FactoryBot.create(:admin) }
  let!(:admin_token) { 'Bearer ' + admin.api_key.access_token }

  header "Content-Type", "application/vnd.api+json"
  authentication :apiKey, :web_token , name: 'OTP-API-KEY'

  let(:country) { FactoryBot.create(:country) }
  let!(:operator) { FactoryBot.create(:operator, country: country) }
  let!(:fmus) { FactoryBot.create_list(:fmu, 5, { country: country, operator: operator }) }

  get "/fmus" do
    route_summary 'Lists all the fmus'
    route_description 'It fetches all the fmus.
If the parameter format=geojson is provided, the fmus will come in the geojson format and all the other parameters will be ignored.
If not, then the request is processed as a typical JSON API request.'

    add_include_parameter example: %w[country operator]
    add_filter_parameters_for V1::FmuResource
    add_field_parameter_for :fmu
    add_paging_parameters
    add_sort_parameter

    context '200' do
      example_request "Listing fmus" do
        expect(status).to eq 200
        expect(JSON.parse(response_body)['data'].count).to eql(fmus.count)
      end
    end
  end

  get 'fmus?format=geojson' do
    route_summary 'Lists all the fmus in geojson format'
    route_description 'All the fmus retrieved in the geojson format'

    context '200' do
      example_request 'Listing fmus in geojson' do
        expect(status).to eql 200
      end
    end
  end

  get "/fmus/tiles/:x/:y/:z" do
    route_summary 'Fetches the vector tiles'
    route_description 'It gets the vector tiles for the provided coordinates and Z index'

    parameter :x, 'X coordinate', in: 'path',
              type: :integer, with_example: true, default: 1, minimum: 1
    parameter :y, 'Y coordinate', in: 'path',
              type: :integer, with_example: true, default: 1, minimum: 1
    parameter :z, 'Z index', in: 'path',
              type: :integer, with_example: true, default: 1, minimum: 1

    context '200' do
      example_request 'Getting highest level tiles' do
        expect(status).to eql 200
      end
    end
  end
end
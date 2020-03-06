require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Countries' do
  explanation "Countries resource"

  let!(:web_user) { FactoryBot.create(:admin) }
  let!(:web_token) { 'Bearer ' + web_user.api_key.access_token }

  let!(:admin) { FactoryBot.create(:admin) }
  let!(:admin_token) { 'Bearer ' + admin.api_key.access_token }

  header "Content-Type", "application/vnd.api+json"
  header 'Authorization', :admin_token
  authentication :apiKey, :web_token , name: 'OTP-API-KEY'

  let(:countries) { FactoryBot.create_list(:country, 5) }
  let!(:operator) { FactoryBot.create_list(:operator, 3, country: countries.first) }
  let!(:fmu) { FactoryBot.create_list(:fmu, 5, { country: countries.first }) }

  get "/countries" do
    route_summary 'Fetches all the countries'
    route_description 'It fetches all the countries and it implements JSON API.
If the parameter "is-active" is absent, it will by default send only the active countries'

    parameter 'is-active', 'true', type: 'boolean', required: false
    add_include_parameter example: %w[fmus operator]
    add_filter_parameters_for V1::CountryResource
    add_field_parameter_for :country
    add_paging_parameters
    add_sort_parameter

    example_request "Listing countries" do
      expect(status).to eq 200
      expect(JSON.parse(response_body)['data'].count).to eql(countries.count)
    end
  end

  get "/countries/:id" do
    route_summary 'Fetches a country by id'
    route_description 'It fetches a country by id and implements the JSON API standard'

    parameter :id, 'id', in: :path, type: :integer
    add_include_parameter(example: %w[fmus operator])
    add_field_parameter_for :country

    let(:id) { countries.first.id }

    context '200' do
      example_request "Get one country" do
        expect(status).to eql 200
        expect(JSON.parse(response_body)['data']['id']).to eql(id.to_s)
      end
    end

    context '404' do
      let(:id) { 1000 }
      example_request 'Country not found' do
        expect(status).to eql 404
      end
    end
  end
end
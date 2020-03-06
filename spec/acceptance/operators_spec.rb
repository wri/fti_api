require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Operators' do
  explanation "Operators resource"

  let!(:web_user) { FactoryBot.create(:admin) }
  let!(:web_token) { 'Bearer ' + web_user.api_key.access_token }

  let!(:admin) { FactoryBot.create(:admin) }
  let!(:admin_token) { 'Bearer ' + admin.api_key.access_token }

  header "Content-Type", "application/vnd.api+json"
  header 'Authorization', :admin_token

  let(:country) { FactoryBot.create :country }
  let!(:operators) { FactoryBot.create_list(:operator, 5, country: country) }
  let!(:fmu) { FactoryBot.create_list(:fmu, 5, { country: country, operator: operators.first }) }

  authentication :apiKey, :web_token , name: 'OTP-API-KEY'

  get "/operators" do
    route_summary 'Fetches the operators'
    route_description 'Fetches the operators using the JSON API standard'

    add_include_parameter example: %w[country fmus]
    add_filter_parameters_for V1::OperatorResource
    add_field_parameter_for :operator
    add_paging_parameters
    add_sort_parameter

    example_request "Listing operators" do
      expect(status).to eq 200
    end
  end

  get '/operators/:id' do
    route_summary 'Fetches an operator by id'
    route_description 'Fetches an operator by id and implements the JSON API spec'

    parameter :id, 'id', in: :path, type: :integer
    add_include_parameter(example: %w[fmus country])
    add_field_parameter_for :operator

    let(:id) { Operator.first.id }

    context '200' do
      example_request 'Fetches operator' do
        expect(status).to eql 200
      end
    end

    context '404' do
      let (:id) { 1000 }

      example_request 'Cannot find operator by id' do
        expect(status).to eql 404
      end
    end
  end
end
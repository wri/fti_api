require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__create' do |model_name, valid_params, invalid_params, error_attributes|
  context "Create #{model_name.plural}" do
    let(:route) { "/#{model_name.route_key}" }
    let(:error) { jsonapi_errors(*error_attributes) }

    describe 'For admin user' do
      it "Returns error object when the #{model_name.singular} cannot be created by admin" do
        post(route,
             params: jsonapi_params(model_name.collection, nil, invalid_params),
             headers: admin_headers)

        # expect(status).to eq(422)
        expect(parsed_body).to eq(error)
      end

      it "Returns success object when the #{model_name.singular} was seccessfully created by admin" do
        post(route,
             params: jsonapi_params(model_name.collection, nil, valid_params),
             headers: admin_headers)

        # expect(status).to eq(201)
        expect(parsed_data[:id]).not_to be_empty
        valid_params.each do |name, value|
          expect(parsed_attributes[name]).to eq(value)
        end
      end
    end

    describe 'For not admin user' do
      it "Do not allows to create #{model_name.singular} by not admin user" do
        post(route,
             params: jsonapi_params(model_name.collection, nil, valid_params),
             headers: user_headers)

        expect(status).to eq(401)
        expect(parsed_body).to eq(default_status_errors(401))
      end
    end
  end
end

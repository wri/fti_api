require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__edit' do |model_name, valid_params, invalid_params, error_attributes|
  context "Edit #{model_name.plural}" do
    let(:resource) { FactoryBot.create(model_name.singular.to_sym) }
    let(:route) { "/#{model_name.route_key}/#{resource.id}" }
    let(:error) { jsonapi_errors(*error_attributes) }

    describe 'For admin user' do
      it "Returns error object when the #{model_name.singular} cannot be updated by admin" do
        patch(route,
              params: jsonapi_params(model_name.collection, resource.id, invalid_params),
              headers: admin_headers)

        expect(status).to eq(422)
        expect(parsed_body).to eq(error)
      end

      it "Returns success object when the #{model_name.singular} was seccessfully updated by admin" do
        patch(route,
              params: jsonapi_params(model_name.collection, resource.id, valid_params),
              headers: admin_headers)

        expect(status).to eq(200)
        valid_params.each do |name, value|
          expect(parsed_attributes[name]).to eq(value)
        end
      end
    end

    describe 'For not admin user' do
      it "Do not allows to update #{model_name.singular} by not admin user" do
        patch(route,
              params: jsonapi_params(model_name.collection, resource.id, valid_params),
              headers: user_headers)

        expect(status).to eq(401)
        expect(parsed_body).to eq(default_status_errors(401))
      end
    end
  end
end

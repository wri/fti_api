require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__edit' do |options|
  context "Edit" do
    let(:resource) { create(@singular.to_sym) }
    let(:route) { "/#{@route_key}/#{resource.id}" }
    let(:success_headers) { options[:success_role] ? authorize_headers(create(options[:success_role]).id) : webuser_headers }
    let(:failure_headers) { options[:failure_role] ? authorize_headers(create(options[:failure_role]).id) : webuser_headers }

    describe 'For admin user' do
      it "Returns error object when cannot be updated by admin" do
        patch(route,
              params: jsonapi_params(@collection, resource.id, options[:invalid_params]),
              headers: success_headers)

        expect(parsed_body).to eq(jsonapi_errors(*options[:error_attributes]))
        expect(status).to eq(422)
      end

      it "Returns success object when was seccessfully updated by admin" do
        patch(route,
              params: jsonapi_params(@collection, resource.id, options[:valid_params]),
              headers: success_headers)

        expect(status).to eq(200)
        options[:valid_params]
          .except(*options[:excluded_params])
          .each { |name, value| expect(parsed_attributes[name]).to eq(value) }
      end
    end

    describe 'For not admin user' do
      it "Do not allows to update by not admin user" do
        patch(route,
              params: jsonapi_params(@collection, resource.id, options[:valid_params]),
              headers: failure_headers)

        expect(parsed_body).to eq(default_status_errors(401))
        expect(status).to eq(401)
      end
    end
  end
end

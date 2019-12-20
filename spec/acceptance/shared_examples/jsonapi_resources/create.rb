require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__create' do |options|

  context "Create" do
    let(:route) { "/#{@route_key}" }
    let(:success_headers) { options[:success_role] ? authorize_headers(create(options[:success_role]).id) : webuser_headers }
    let(:failure_headers) { options[:failure_role] ? authorize_headers(create(options[:failure_role]).id) : webuser_headers }

    describe 'For admin user' do
      it "Returns error object when cannot be created by admin" do
        post(route,
             params: jsonapi_params(@collection, nil, options[:invalid_params]),
             headers: success_headers)

        expect(parsed_body).to eq(jsonapi_errors(*options[:error_attributes]))
        expect(status).to eq(422)
      end

      it "Returns success object when was seccessfully created by admin" do
        post(route,
             params: jsonapi_params(@collection, nil, options[:valid_params]),
             headers: success_headers)

        expect(parsed_data[:id]).not_to be_empty
        options[:valid_params]
          .except(*options[:excluded_params])
          .each { |name, value| expect(parsed_attributes[name]).to eq(value) }
        expect(status).to eq(201)
      end
    end

    if options[:failure_headers]
      describe 'For not admin user' do
        it "Do not allows to create by not admin user" do
          post(route,
               params: jsonapi_params(@collection, nil, options[:valid_params]),
               headers: failure_headers)

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
        end
      end
    end
  end
end

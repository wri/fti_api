RSpec.shared_examples 'jsonapi-resources__create' do |options|

  context "Create" do
    let(:route) { "/#{@route_key}" }

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it "Returns error object when cannot be created by admin" do
          post(route,
               params: jsonapi_params(@collection, nil, options[:invalid_params]),
               headers: headers)

          expect(parsed_body).to eq(jsonapi_errors(*options[:error_attributes]))
          expect(status).to eq(422)
        end

        it "Returns success object when was successfully created by admin" do
          post(route,
               params: jsonapi_params(@collection, nil, options[:valid_params]),
               headers: headers)

          expect(parsed_data[:id]).not_to be_empty
          options[:valid_params]
            .except(*options[:excluded_params])
            .each { |name, value| expect(parsed_attributes[name]).to eq(value) }
          expect(status).to eq(201)
        end
      end
    end

    (options[:failure_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it "Do not allows to create by not admin user" do
          post(route,
               params: jsonapi_params(@collection, nil, options[:valid_params]),
               headers: headers)

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
        end
      end
    end

  end
end

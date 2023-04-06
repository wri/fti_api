RSpec.shared_examples "jsonapi-resources__delete" do |options|
  context "Delete" do
    let(:resource) { try_to_call(options[:resource]) || create(options[:factory] || @singular.to_sym) }
    let(:route) { "/#{@route_key}/#{resource.id}" }

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it "Returns success object when was successfully deleted by #{role}" do
          delete route, headers: headers

          expect(status).to eq(204)
          expect(@model_class.exists?(resource.id)).to be_falsey
        end
      end
    end

    (options[:failure_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it "Do not allows to delete by not #{role}" do
          delete route, headers: headers

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
          expect(@model_class.exists?(resource.id)).to be_truthy
        end
      end
    end
  end
end

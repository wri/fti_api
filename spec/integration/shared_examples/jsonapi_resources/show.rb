RSpec.shared_examples "jsonapi-resources__show" do |options|
  context "Show" do
    let!(:resource) { try_to_call(options[:resource]) || create(@singular.to_sym) }

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        if options.fetch(:index, true)
          it "Get list" do
            get "/#{@route_key}", headers: headers
            expect(status).to eq(200)
          end
        end

        if options.fetch(:show, true)
          it "Get specific" do
            get "/#{@route_key}/#{resource.id}", headers: headers
            expect(status).to eq(200)
          end
        end
      end
    end
  end
end

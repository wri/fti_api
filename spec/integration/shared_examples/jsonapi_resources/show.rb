require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__show' do |options|
  context "Show" do
    let!(:resource) { create(@singular.to_sym) }

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it "Get list" do
          get "/#{@route_key}", headers: headers
          expect(status).to eq(200)
        end

        it "Get specific" do
          get "/#{@plural}/#{resource.id}", headers: headers
          expect(status).to eq(200)
        end
      end
    end
  end
end

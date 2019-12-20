require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__show' do |options|
  context "Show" do
    let(:success_headers) { options[:success_role] ? authorize_headers(create(options[:success_role]).id) : webuser_headers }
    let!(:resource) { create(@singular.to_sym) }

    it "Get list" do
      get "/#{@route_key}", headers: success_headers
      expect(status).to eq(200)
    end

    it "Get specific" do
      get "/#{@plural}/#{resource.id}", headers: success_headers
      expect(status).to eq(200)
    end
  end
end

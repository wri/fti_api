require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__show' do |model_name|
  context "Show #{model_name.plural}" do
    let(:resource) { FactoryBot.create(model_name.singular.to_sym) }

    it "Get #{model_name.plural} list" do
      get "/#{model_name.route_key}", headers: webuser_headers
      expect(status).to eq(200)
    end

    it "Get specific #{model_name.singular}" do
      get "/#{model_name.plural}/#{resource.id}", headers: webuser_headers
      expect(status).to eq(200)
    end
  end
end

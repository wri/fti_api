require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__transleatable' do |model_class, options|
  context "Translateable" do
    let(:success_headers) { options[:success_headers] }
    let(:locales) { options[:locales].keys }
    let!(:resource) { create(model_class.model_name.singular.to_sym) }

    options[:locales].keys.each do |locale|
      it "Get for #{locale} locale" do
        get "/#{model_class.model_name.route_key}", headers: success_headers
        expect(status).to eq(200)
      end
    end
  end
end

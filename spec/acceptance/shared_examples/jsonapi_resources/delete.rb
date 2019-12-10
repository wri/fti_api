require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__delete' do |model_class, model_name|
  context "Delete #{model_name.plural}" do
    let(:resource) { FactoryBot.create(model_name.singular.to_sym) }
    let(:route) { "/#{model_name.route_key}/#{resource.id}" }

    describe 'For admin user' do
      it "Returns success object when the #{model_name.singular} was seccessfully deleted by admin" do
        delete route, headers: admin_headers

        expect(status).to eq(204)
        expect(model_class.exists?(resource.id)).to be_falsey
      end
    end

    describe 'For not admin user' do
      it "Do not allows to delete #{model_name.singular} by not admin user" do
        delete route, headers: user_headers

        expect(status).to eq(401)
        expect(parsed_body).to eq(default_status_errors(401))
        expect(model_class.exists?(resource.id)).to be_truthy
      end
    end
  end
end

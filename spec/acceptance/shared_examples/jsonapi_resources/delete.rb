require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__delete' do |options|
  context "Delete" do
    let(:resource) { create(@singular.to_sym) }
    let(:route) { "/#{@route_key}/#{resource.id}" }
    let(:success_headers) { options[:success_role] ? authorize_headers(create(options[:success_role]).id) : webuser_headers }
    let(:failure_headers) { options[:failure_role] ? authorize_headers(create(options[:failure_role]).id) : webuser_headers }

    describe 'For admin user' do
      it "Returns success object when was seccessfully deleted by admin" do
        delete route, headers: success_headers

        expect(@model_class.exists?(resource.id)).to be_falsey
        expect(status).to eq(204)
      end
    end

    describe 'For not admin user' do
      it "Do not allows to delete by not admin user" do
        delete route, headers: failure_headers

        expect(parsed_body).to eq(default_status_errors(401))
        expect(status).to eq(401)
        expect(@model_class.exists?(resource.id)).to be_truthy
      end
    end
  end
end

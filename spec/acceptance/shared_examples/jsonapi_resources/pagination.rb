require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__pagination' do |options|
  context "Pagination" do
    let(:attributes) { options[:attributes] || {} }

    before(:context) do
      @model_class.destroy_all
      @collection = create_list(@singular.to_sym, 6, options[:attributes] || {})
    end

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it 'Show list for first page with per pege param' do
          get "/#{@route_key}?page[number]=1&page[size]=3", headers: headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(3)
        end

        it 'Show list second page with per pege param' do
          get "/#{@route_key}?page[number]=2&page[size]=3", headers: headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(3)
        end
      end
    end

  end
end

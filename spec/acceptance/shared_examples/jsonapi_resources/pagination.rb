require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__pagination' do |options|
  context "Pagination" do
    let(:success_headers) { options[:success_role] ? authorize_headers(create(options[:success_role]).id) : webuser_headers }
    let(:attributes) { options[:attributes] || {} }

    before(:context) do
      @model_class.destroy_all
      @collection = create_list(@singular.to_sym, 6, options[:attributes] || {})
    end

    it 'Show list for first page with per pege param' do
      get "/#{@route_key}?page[number]=1&page[size]=3", headers: success_headers

      expect(status).to eq(200)
      expect(parsed_data.size).to eq(3)
    end

    it 'Show list second page with per pege param' do
      get "/#{@route_key}?page[number]=2&page[size]=3", headers: success_headers

      expect(status).to eq(200)
      expect(parsed_data.size).to eq(3)
    end
  end
end

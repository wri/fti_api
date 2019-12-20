require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__filter' do |options|
  context "Filter" do
    let(:success_headers) { options[:success_role] ? authorize_headers(create(options[:success_role]).id) : webuser_headers }

    before(:context) do
      @model_class.destroy_all

      options[:filters].each do |filter|
        (filter[:expected_count] || 3).times do |i|
          create(@singular.to_sym, filter[:attributes])
        end
      end
    end

    options[:filters].each do |filter|
      context "attributes: " do
        let(:route_params) { filter[:attributes].map { |k, v| "#{k}=#{v}" }.join('&') }

        it filter[:attributes].map { |k, v| "#{k}=#{v}" }.join('&') do
          get "/#{@route_key}?#{route_params}", headers: success_headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(filter[:expected_count] || 3)
        end
      end
    end
  end
end

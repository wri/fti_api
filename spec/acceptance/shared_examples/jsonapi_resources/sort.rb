require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__sort' do |options|
  context "Sort" do
    let(:jsonapi_attribute) { options[:attribute].to_s.gsub('_', '-').to_sym }
    let(:expected_count) { options[:expected_count] || 6 }
    let(:desc) { options[:desc] || options[:sequence].call(expected_count - 1) }
    let(:asc) { options[:asc] || options[:sequence].call(0) }

    before(:context) do
      @model_class.destroy_all

      6.times do |i|
        create(@singular.to_sym, options[:attribute] => options[:sequence].call(i))
      end
    end

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        it "Show list sorted by #{options[:attribute]}" do
          get "/#{@route_key}?sort=#{options[:attribute]}", headers: headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(expected_count)
          expect(parsed_data[0][:attributes][jsonapi_attribute]).to eq(asc)
        end

        it "Show list sorted by #{options[:attribute]} DESC" do
          get "/#{@route_key}?sort=-#{options[:attribute]}", headers: headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(expected_count)
          expect(parsed_data[0][:attributes][jsonapi_attribute]).to eq(desc)
        end
      end
    end

  end
end

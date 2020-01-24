require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources__translations' do |options|
  context "Translations" do
    let(:locales) { options[:locales] || [] }

    let!(:resource) do
      resource = create(@singular.to_sym, options[:attributes])

      locales.each do |locale|
        resource.attributes =
          options[:attributes].map { |key, value| [key, "#{value} #{locale}"] }
                              .to_h.merge(locale: locale)
      end

      resource.save
      resource
    end

    (options[:success_roles] || [:webuser]).each do |role|
      describe "For user with #{role} role" do
        let(:headers) { respond_to?("#{role}_headers") ? send("#{role}_headers") : authorize_headers(create(role).id) }

        # multiplying array of locales to trigger caching by locale
        (options[:locales] * 2 || []).each do |locale|
          it "Get for #{locale} locale" do
            get "/#{@route_key}?locale=#{locale}", headers: headers

            expect(status).to eq(200)
            options[:attributes].each do |key, value|
              expect(parsed_data[0][:attributes][key.to_sym]).to eq("#{value} #{locale}")
            end
          end
        end
      end
    end
  end
end

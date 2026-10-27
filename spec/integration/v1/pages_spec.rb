require "rails_helper"

module V1
  describe "Page", type: :request do
    it_behaves_like "jsonapi-resources", Page, {
      translations: {
        locales: [:en, :fr],
        attributes: {title: "Title", body: "Body"}
      },
      route_key: "pages"
    }

    describe "sections" do
      let!(:page) { create(:page, slug: "about") }
      let!(:donors) { create(:page_section, page: page, title: "Donors", body: nil, code: "donors") }
      let!(:intro) { create(:page_section, page: page, title: "What is OTP", body: "<p>Text</p>") }

      around do |example|
        cache = JSONAPI.configuration.resource_cache
        JSONAPI.configuration.resource_cache = ActiveSupport::Cache::MemoryStore.new
        example.run
      ensure
        JSONAPI.configuration.resource_cache = cache
      end

      before do
        intro.insert_at(1)
        create(:page_section, title: "Other page section")
      end

      def get_about(locale: :en)
        get "/pages?filter[slug]=about&include=sections&locale=#{locale}", headers: jsonapi_headers
      end

      def included_sections
        parsed_body[:included].select { it[:type] == "page-sections" }.sort_by { it[:attributes][:position] }
      end

      it "returns the page sections in order" do
        get_about

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(1)
        expect(parsed_data[0][:relationships][:sections][:data].pluck(:id)).to eq([intro.id.to_s, donors.id.to_s])
        expect(included_sections.pluck(:attributes)).to eq([
          {position: 1, code: nil, title: "What is OTP", body: "<p>Text</p>"},
          {position: 2, code: "donors", title: "Donors", body: nil}
        ])
      end

      it "returns translated sections" do
        I18n.with_locale(:fr) { intro.update!(title: "Qu'est-ce que l'OTP") }

        get_about(locale: :fr)

        expect(included_sections.first[:attributes][:title]).to eq("Qu'est-ce que l'OTP")
      end

      it "returns section changes after the page was cached" do
        get_about
        expect(included_sections.first[:attributes][:title]).to eq("What is OTP")

        travel_to(1.minute.from_now) { intro.update!(title: "What is the OTP") }
        get_about

        expect(included_sections.first[:attributes][:title]).to eq("What is the OTP")
      end

      it "returns added sections after the page was cached" do
        get_about
        travel_to(1.minute.from_now) { create(:page_section, page: page, title: "Partners", body: nil, code: "partners") }
        get_about

        expect(included_sections.map { it[:attributes][:code] }).to eq([nil, "donors", "partners"])
      end
    end
  end
end

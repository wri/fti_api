require "rails_helper"

RSpec.describe TrackFileDownloadJob, type: :job do
  let(:file_url) { "https://example.com/files/document.pdf" }
  let(:file_name) { "document.pdf" }
  let(:model_name) { "User" }
  let(:measurement_id) { "G-XXXXXXXXXX" }
  let(:api_secret) { "test_api_secret" }
  let(:client_id) { "test_client" }
  let(:client_ip) { "81.2.69.142" }
  let(:referer) { "https://example.com" }
  let(:request_source) { "search_engine" }
  let(:request_source_info) { "google" }
  let(:expected_location) do
    {
      country: "United Kingdom",
      country_code: "GB",
      city: "London",
      region: "England"
    }
  end

  before do
    ENV["GA4_MEASUREMENT_ID"] = measurement_id
    ENV["GA4_API_SECRET"] = api_secret
  end

  after do
    ENV.delete("GA4_MEASUREMENT_ID")
    ENV.delete("GA4_API_SECRET")
  end

  describe "#perform" do
    context "when environment variables are present" do
      let(:expected_payload) do
        {
          client_id: client_id,
          events: [{
            name: "server_file_download",
            params: {
              file_name: file_name,
              file_extension: "pdf",
              file_url: file_url,
              link_url: file_url,
              model_name: model_name,
              page_referer: referer,
              source: request_source,
              source_info: request_source_info,
              **expected_location
            }
          }],
          user_location: {
            city: expected_location[:city],
            country_id: expected_location[:country_code]
          }
        }
      end

      let(:expected_params) do
        {
          measurement_id: measurement_id,
          api_secret: api_secret
        }
      end

      it "sends a GA4 event with correct payload" do
        expect(HTTP).to receive(:post).with(
          "https://www.google-analytics.com/mp/collect",
          params: expected_params,
          json: expected_payload
        )

        described_class.perform_now(client_id, client_ip, referer, request_source, request_source_info, file_url, file_name, model_name)
      end
    end

    context "when measurement_id is blank" do
      before do
        ENV["GA4_MEASUREMENT_ID"] = ""
      end

      it "does not send GA4 event" do
        expect(HTTP).not_to receive(:post)
        described_class.perform_now(client_id, client_ip, referer, request_source, request_source_info, file_url, file_name, model_name)
      end
    end

    context "when api_secret is blank" do
      before do
        ENV["GA4_API_SECRET"] = ""
      end

      it "does not send GA4 event" do
        expect(HTTP).not_to receive(:post)
        described_class.perform_now(client_id, client_ip, referer, request_source, request_source_info, file_url, file_name, model_name)
      end
    end
  end
end

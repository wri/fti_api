require "rails_helper"

RSpec.describe TrackFileDownloadJob, type: :job do
  let(:file_url) { "https://example.com/files/document.pdf" }
  let(:file_name) { "document.pdf" }
  let(:model_name) { "User" }
  let(:measurement_id) { "G-XXXXXXXXXX" }
  let(:api_secret) { "test_api_secret" }
  let(:client_id) { "test_client" }

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
            name: "file_download",
            params: {
              file_name: file_name,
              file_extension: "pdf",
              file_url: file_url,
              link_url: file_url,
              model_name: model_name
            }
          }]
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

        described_class.perform_now(client_id, file_url, file_name, model_name)
      end
    end

    context "when measurement_id is blank" do
      before do
        ENV["GA4_MEASUREMENT_ID"] = ""
      end

      it "does not send GA4 event" do
        expect(HTTP).not_to receive(:post)
        described_class.perform_now(client_id, file_url, file_name, model_name)
      end
    end

    context "when api_secret is blank" do
      before do
        ENV["GA4_API_SECRET"] = ""
      end

      it "does not send GA4 event" do
        expect(HTTP).not_to receive(:post)
        described_class.perform_now(client_id, file_url, file_name, model_name)
      end
    end
  end
end

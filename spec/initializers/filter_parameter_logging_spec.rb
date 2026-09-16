require "rails_helper"

RSpec.describe "Parameter filtering" do
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }
  let(:attachment) { "data:application/pdf;base64,#{Base64.strict_encode64("%PDF-1.7" * 100)}" }
  let(:params) do
    {
      "data" => {
        "type" => "operator-document-fmus",
        "attributes" => {"start-date" => "2026-09-09", "attachment" => attachment, "email" => "user@example.com"}
      },
      "files" => [attachment, "report.pdf"]
    }
  end

  subject(:filtered) { filter.filter(params) }

  it "replaces base64 data URIs with their content type and size" do
    expect(filtered.dig("data", "attributes", "attachment")).to eq("[FILTERED data:application/pdf #{attachment.bytesize} bytes]")
    expect(filtered["files"]).to eq(["[FILTERED data:application/pdf #{attachment.bytesize} bytes]", "report.pdf"])
  end

  it "keeps other values and existing filters" do
    expect(filtered.dig("data", "attributes", "start-date")).to eq("2026-09-09")
    expect(filtered.dig("data", "attributes", "email")).to eq("[FILTERED]")
  end

  it "does not modify the original params" do
    filtered
    expect(params.dig("data", "attributes", "attachment")).to eq(attachment)
    expect(params["files"].first).to eq(attachment)
  end
end

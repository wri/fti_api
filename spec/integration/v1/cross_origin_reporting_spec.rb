require "rails_helper"

module V1
  describe "Cross origin reporting", type: :request do
    before { set_reporting_flag("true") }

    def set_reporting_flag(value)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with(CrossOriginReporting::ENABLED_ENV_VAR).and_return(value)
    end

    it "does nothing unless the reporting flag is enabled" do
      set_reporting_flag(nil)

      expect(Sentry).not_to receive(:capture_message)

      get "/countries", headers: {"Origin" => "https://otp-api.example.org"}
    end

    it "reports a request carrying a foreign origin" do
      expect(Sentry).to receive(:capture_message).with(
        "API request from unexpected origin https://otp-api.example.org",
        hash_including(level: :error)
      )

      get "/countries", headers: {"Origin" => "https://otp-api.example.org"}
    end

    # the misconfigured frontend is the point, so the report has to happen
    # whether or not the request would have been allowed through
    it "reports even when the request is rejected as unauthenticated" do
      expect(Sentry).to receive(:capture_message)

      get "/users/current-user", headers: {"Origin" => "https://otp-api.example.org"}

      expect(status).to eq(401)
    end

    it "tags the report with the calling app" do
      expect(Sentry).to receive(:capture_message).with(
        anything,
        hash_including(tags: hash_including(app: "observations-tool"))
      )

      get "/countries?app=observations-tool", headers: {"Origin" => "https://otp-api.example.org"}
    end

    it "does not report a request from our own origin" do
      expect(Sentry).not_to receive(:capture_message)

      get "/countries", headers: {"Origin" => "http://www.example.com"}
    end

    it "does not report a request without an origin" do
      expect(Sentry).not_to receive(:capture_message)

      get "/countries"
    end

    it "does not report an implausibly long origin" do
      expect(Sentry).not_to receive(:capture_message)

      get "/countries", headers: {"Origin" => "https://#{"a" * 250}.example.org"}
    end

    it "reports a given origin only once per throttle window" do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      expect(Sentry).to receive(:capture_message).once

      2.times { get "/countries", headers: {"Origin" => "https://otp-api.example.org"} }
    end

    it "reports each distinct origin separately" do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      expect(Sentry).to receive(:capture_message).twice

      get "/countries", headers: {"Origin" => "https://otp-api.example.org"}
      get "/countries", headers: {"Origin" => "https://old-staging.example.org"}
    end
  end
end

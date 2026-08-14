require "rails_helper"

module V1
  describe "Disabling bearer auth", type: :request do
    def disable_bearer_auth
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with(APIController::DISABLE_BEARER_AUTH_ENV_VAR).and_return("true")
    end

    def login_with_cookie
      post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}
    end

    it "accepts a bearer token while the switch is off" do
      get "/users/current-user", headers: user_headers

      expect(status).to eq(200)
    end

    it "rejects a bearer token once the switch is on" do
      disable_bearer_auth

      get "/users/current-user", headers: user_headers

      expect(status).to eq(401)
    end

    it "still authenticates with the auth cookie" do
      login_with_cookie
      disable_bearer_auth

      get "/users/current-user"

      expect(status).to eq(200)
      expect(parsed_attributes[:email]).to eq(user.email)
    end

    # the CSRF exemption keys off the Authorization header, so disabling bearer
    # auth has to hide the header from that check too — otherwise a leftover
    # token would wave a cookie-authenticated write straight past CSRF
    it "still enforces CSRF on a cookie-authenticated request carrying a stale token" do
      login_with_cookie
      disable_bearer_auth

      delete "/logout", headers: {"Authorization" => "Bearer #{generate_token(user.id)}"}

      expect(status).to eq(403)
    end

    it "allows the same request when the CSRF header is present" do
      login_with_cookie
      disable_bearer_auth

      delete "/logout", headers: {
        "Authorization" => "Bearer #{generate_token(user.id)}",
        APIController::CSRF_HEADER => cookies[APIController::CSRF_COOKIE_NAME]
      }

      expect(status).to eq(204)
    end

    it "keeps issuing a token at login so frontends reading the field do not break" do
      disable_bearer_auth

      post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

      expect(status).to eq(200)
      expect(parsed_body[:token]).to be_present
    end
  end
end

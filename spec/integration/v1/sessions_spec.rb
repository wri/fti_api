require "rails_helper"

module V1
  describe "Sessions management", type: :request do
    it "Returns error object when the user cannot login" do
      post "/login", params: {auth: {email: user.email, password: "wrong password"}}

      expect(status).to eq(401)
      expect(parsed_body).to eq({errors: [{status: 401, title: "Incorrect email or password"}]})
    end

    it "Valid login" do
      post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

      expect(status).to eq(200)
      expect(parsed_body).to eq({
        role: "user",
        user_id: user.id,
        country: nil, operator_ids: [], observer: nil
      })
      expect(response.cookies["download_user"]).to be_present
      expect(user.reload.should_change_password).to eq(false)
    end

    it "Login with weak password sets should_change_password flag" do
      user = build(:admin, password: "weak", password_confirmation: "weak")
      user.save!(validate: false)

      post "/login", params: {auth: {email: user.email, password: "weak"}}

      expect(status).to eq(200)
      expect(user.reload.should_change_password).to eq(true)
    end

    describe "Auth cookie" do
      it "does not set auth cookie by default" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_nil
      end

      it "sets an opaque auth cookie when set_cookie param is true" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        expect(status).to eq(200)
        cookie = response.cookies[APIController::AUTH_COOKIE_NAME]
        expect(cookie).to be_present
        # the cookie is encrypted, so it never exposes the raw user id
        expect(cookie).not_to eq(user.id.to_s)
      end

      it "sets a separate auth cookie per app" do
        post "/login?app=observations-tool", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        expect(status).to eq(200)
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_nil
        expect(response.cookies["observations-tool_#{APIController::AUTH_COOKIE_NAME}"]).to be_present
      end

      it "sets a session cookie (no expiry) by default" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        expect(status).to eq(200)
        set_cookie = auth_set_cookie_header
        expect(set_cookie).to be_present
        expect(set_cookie).not_to match(/expires=/i)
        expect(set_cookie).not_to match(/max-age=/i)
      end

      it "sets a persistent cookie when remember_me is true" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true, remember_me: true}}

        expect(status).to eq(200)
        expect(auth_set_cookie_header).to match(/expires=/i)
      end

      it "authenticates a request using the auth cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        get "/users/current-user"

        expect(status).to eq(200)
        expect(parsed_attributes[:email]).to eq(user.email)
      end

      it "authenticates a request using the app-namespaced auth cookie" do
        post "/login?app=observations-tool", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        get "/users/current-user?app=observations-tool"

        expect(status).to eq(200)
        expect(parsed_attributes[:email]).to eq(user.email)
      end

      it "does not authenticate when the app does not match the cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        # cookie was set for the portal (no app), so the observations-tool app
        # cannot read it
        get "/users/current-user?app=observations-tool"

        expect(status).to eq(401)
      end

      it "logout clears the auth cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_present

        delete "/logout", headers: {APIController::CSRF_HEADER => cookies[APIController::CSRF_COOKIE_NAME]}

        expect(status).to eq(204)
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_blank
      end
    end

    describe "CSRF protection" do
      it "issues a non-HTTP-only XSRF-TOKEN cookie at login" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        expect(response.cookies[APIController::CSRF_COOKIE_NAME]).to be_present
        csrf_set_cookie = Array(response.headers["Set-Cookie"]).find { |c| c.start_with?("#{APIController::CSRF_COOKIE_NAME}=") }
        expect(csrf_set_cookie).not_to match(/httponly/i)
      end

      it "blocks cookie-authenticated unsafe requests without the CSRF header" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        delete "/logout"

        expect(status).to eq(403)
      end

      it "blocks cookie-authenticated unsafe requests with a mismatched CSRF header" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        delete "/logout", headers: {APIController::CSRF_HEADER => "not-the-real-token"}

        expect(status).to eq(403)
      end

      it "allows cookie-authenticated unsafe requests when the header matches" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        delete "/logout", headers: {APIController::CSRF_HEADER => cookies[APIController::CSRF_COOKIE_NAME]}

        expect(status).to eq(204)
      end

      it "exempts safe (GET) cookie-authenticated requests from CSRF" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        get "/users/current-user"

        expect(status).to eq(200)
      end

      it "exempts requests not authenticated via the auth cookie from CSRF" do
        # no auth cookie means the CSRF check is skipped; the request is then
        # rejected by authentication rather than CSRF
        delete "/logout"

        expect(status).to eq(401)
      end

      it "re-issues the XSRF-TOKEN cookie when it's missing on a cookie-authed request" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        # simulate the XSRF cookie being cleared while the auth cookie persists
        cookies.delete(APIController::CSRF_COOKIE_NAME)

        delete "/logout"

        # the current request still fails CSRF (no header could be sent)...
        expect(status).to eq(403)
        # ...but the response includes a fresh XSRF cookie so the frontend can retry
        expect(response.cookies[APIController::CSRF_COOKIE_NAME]).to be_present
      end

      it "logout clears the XSRF-TOKEN cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", set_cookie: true}}

        delete "/logout", headers: {APIController::CSRF_HEADER => cookies[APIController::CSRF_COOKIE_NAME]}

        expect(response.cookies[APIController::CSRF_COOKIE_NAME]).to be_blank
      end
    end

    describe "Download session" do
      it "Destroy session removes download cookie" do
        post "/sessions/download-session", headers: user_headers

        expect(status).to eq(200)
        expect(response.cookies["download_user"]).to be_present

        delete "/logout", headers: user_headers

        expect(status).to eq(204)
        expect(response.headers["Set-Cookie"]).to include("download_user=;")
        expect(response.cookies["download_user"]).to be_blank
      end

      it "Download session sets download cookie for authenticated user" do
        post "/sessions/download-session", headers: user_headers

        expect(status).to eq(200)
        download_token = response.cookies["download_user"]
        expect(download_token).to be_present
        payload = Rails.application.message_verifier("download_token").verify(download_token)
        expect(payload["user_id"]).to eq(user.id)
      end

      it "Download session set download cookie for different app" do
        post "/sessions/download-session?app=observations-tool", headers: user_headers

        expect(status).to eq(200)
        expect(response.cookies["observations-tool_download_user"]).to be_present
      end
    end

    describe "For current user" do
      it "Get current user" do
        get "/users/current-user", headers: user_headers
        expect(status).to eq(200)
        expect(parsed_attributes).to eq({
          name: "Test user",
          "first-name": "Test",
          "last-name": "user",
          email: user.email,
          "is-active": true,
          "deactivated-at": nil,
          locale: "en",
          "organization-account": false,
          "permissions-request": nil,
          "permissions-accepted": nil,
          "managed-observer-ids": [],
          "qc1-observer-ids": [],
          "qc2-observer-ids": [],
          "operator-ids": [],
          "country-id": nil,
          "observer-id": nil
        })
      end

      it "Request without valid authorization for current user" do
        get "/users/current-user"
        expect(parsed_body).to eq(default_status_errors(401))
      end
    end
  end
end

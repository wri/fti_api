require "rails_helper"

module V1
  describe "Sessions management", type: :request do
    it "Returns error object when the user cannot login" do
      post "/login", params: {auth: {email: user.email, password: "wrong password"}}

      expect(status).to eq(401)
      expect(parsed_body).to eq({errors: [{status: 401, title: "Incorrect email or password"}]})
      expect(user.reload.failed_attempts).to eq(1)
    end

    describe "Account lockout" do
      it "renders the backoffice login page with the resend unlock link" do
        get new_user_session_path

        expect(response).to be_successful
        expect(response.body).to include(I18n.t("active_admin.devise.links.resend_unlock_instructions"))
      end

      def lock_account!(account)
        Devise.maximum_attempts.times do
          post "/login", params: {auth: {email: account.email, password: "wrong password"}}
          expect(status).to eq(401)
        end
      end

      it "Locks the account after the maximum failed attempts" do
        lock_account!(user)

        expect(user.reload).to be_access_locked

        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(401)
        expect(parsed_body).to eq({errors: [{status: 401, title: "Incorrect email or password"}]})
      end

      it "Sends unlock instructions when the account is locked" do
        expect {
          lock_account!(user)
        }.to have_enqueued_mail(DeviseMailer, :unlock_instructions).once

        expect(user.reload).to be_access_locked
        expect(user.unlock_token).to be_present
      end

      def visit_unlock_link_for(account)
        ActionMailer::Base.deliveries.clear

        perform_enqueued_jobs do
          lock_account!(account)
        end

        expect(account.reload).to be_access_locked

        mail = ActionMailer::Base.deliveries.last
        expect(mail).to be_present
        expect(mail.to).to contain_exactly(account.email)
        expect(mail.subject).to eq(I18n.t("devise.mailer.unlock_instructions.subject"))

        body = (mail.html_part || mail).body.to_s
        unlock_url = body[%r{(https?://[^"]+/unlock\?unlock_token=[^"]+)}, 1]
        expect(unlock_url).to be_present
        expect(unlock_url).not_to include("/admin/unlock")

        get CGI.unescapeHTML(URI.parse(unlock_url).request_uri)
      end

      it "Unlocks the account when the email unlock link is visited" do
        visit_unlock_link_for(user)

        expect(response).to redirect_to(ENV.fetch("FRONTEND_URL"))
        expect(user.reload).not_to be_access_locked
        expect(user.failed_attempts).to eq(0)
        expect(user.unlock_token).to be_nil

        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}
        expect(status).to eq(200)
      end

      it "Redirects operators to the portal after unlock" do
        visit_unlock_link_for(operator_user)

        expect(response).to redirect_to(ENV.fetch("FRONTEND_URL"))
        expect(operator_user.reload).not_to be_access_locked
      end

      it "Redirects observation tool users to the observations tool after unlock" do
        ngo = create(:ngo)

        visit_unlock_link_for(ngo)

        expect(response).to redirect_to(ENV.fetch("OBSERVATIONS_TOOL_URL"))
        expect(ngo.reload).not_to be_access_locked
      end

      it "Redirects admins to the backoffice login after unlock" do
        visit_unlock_link_for(admin)

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:notice]).to eq(I18n.t("devise.unlocks.unlocked"))
        expect(admin.reload).not_to be_access_locked
      end

      it "Resets failed attempts after a successful login" do
        post "/login", params: {auth: {email: user.email, password: "wrong password"}}
        expect(user.reload.failed_attempts).to eq(1)

        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        expect(user.reload.failed_attempts).to eq(0)
      end
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
      it "sets the auth cookie on every login" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_present
      end

      it "sets an opaque auth cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        cookie = response.cookies[APIController::AUTH_COOKIE_NAME]
        expect(cookie).to be_present
        # opaque to the client: the payload is encrypted, so the salt it carries
        # is not readable in the cookie value
        expect(cookie).not_to include(user.authenticatable_salt)
      end

      it "sets a separate auth cookie per app" do
        post "/login?app=observations-tool", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_nil
        expect(response.cookies["observations-tool_#{APIController::AUTH_COOKIE_NAME}"]).to be_present
      end

      it "sets a session cookie (no expiry) by default" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        set_cookie = auth_set_cookie_header
        expect(set_cookie).to be_present
        expect(set_cookie).not_to match(/expires=/i)
        expect(set_cookie).not_to match(/max-age=/i)
      end

      it "sets a persistent cookie when remember_me is true" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1", remember_me: true}}

        expect(status).to eq(200)
        expect(auth_set_cookie_header).to match(/expires=/i)
      end

      it "authenticates a request using the auth cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        get "/users/current-user"

        expect(status).to eq(200)
        expect(parsed_attributes[:email]).to eq(user.email)
      end

      it "authenticates a request using the app-namespaced auth cookie" do
        post "/login?app=observations-tool", params: {auth: {email: user.email, password: "Supersecret1"}}

        get "/users/current-user?app=observations-tool"

        expect(status).to eq(200)
        expect(parsed_attributes[:email]).to eq(user.email)
      end

      it "ignores an unknown app and falls back to the portal cookie" do
        post "/login?app=bogus", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(status).to eq(200)
        expect(response.cookies["bogus_#{APIController::AUTH_COOKIE_NAME}"]).to be_nil
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_present
      end

      it "stops authenticating once the password changes" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        get "/users/current-user"
        expect(status).to eq(200)

        user.update!(password: "Supersecret2", password_confirmation: "Supersecret2")

        get "/users/current-user"
        expect(status).to eq(401)
      end

      it "does not authenticate when the app does not match the cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        # cookie was set for the portal (no app), so the observations-tool app
        # cannot read it
        get "/users/current-user?app=observations-tool"

        expect(status).to eq(401)
      end

      it "logout clears the auth cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_present

        delete "/logout", headers: {APIController::CSRF_HEADER => cookies[APIController::CSRF_COOKIE_NAME]}

        expect(status).to eq(204)
        expect(response.cookies[APIController::AUTH_COOKIE_NAME]).to be_blank
      end
    end

    describe "CSRF protection" do
      it "issues a non-HTTP-only XSRF-TOKEN cookie at login" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        expect(response.cookies[APIController::CSRF_COOKIE_NAME]).to be_present
        csrf_set_cookie = Array(response.headers["Set-Cookie"]).find { |c| c.start_with?("#{APIController::CSRF_COOKIE_NAME}=") }
        expect(csrf_set_cookie).not_to match(/httponly/i)
      end

      it "issues a URL-safe token so the frontend can echo it back verbatim" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        csrf_set_cookie = Array(response.headers["Set-Cookie"]).find { |c| c.start_with?("#{APIController::CSRF_COOKIE_NAME}=") }
        value = csrf_set_cookie.split("=", 2).last.split(";").first
        # no percent-encoding in the raw header means document.cookie needs no decoding
        expect(value).to match(/\A[A-Za-z0-9_-]+--[a-f0-9]+\z/)
      end

      it "blocks cookie-authenticated unsafe requests without the CSRF header" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        delete "/logout"

        expect(status).to eq(403)
      end

      it "blocks cookie-authenticated unsafe requests with a mismatched CSRF header" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        delete "/logout", headers: {APIController::CSRF_HEADER => "not-the-real-token"}

        expect(status).to eq(403)
      end

      it "allows cookie-authenticated unsafe requests when the header matches" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        delete "/logout", headers: {APIController::CSRF_HEADER => cookies[APIController::CSRF_COOKIE_NAME]}

        expect(status).to eq(204)
      end

      it "rejects a matching cookie and header that is not signed by the app" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        forged = "not-a-signed-token"
        cookies[APIController::CSRF_COOKIE_NAME] = forged
        delete "/logout", headers: {APIController::CSRF_HEADER => forged}

        expect(status).to eq(403)
      end

      it "rejects a token signed for another user" do
        other_user = create(:admin)
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        other_token = CsrfProtection.verifier
          .generate({"user_id" => other_user.id, "nonce" => SecureRandom.urlsafe_base64(16)})
        cookies[APIController::CSRF_COOKIE_NAME] = other_token
        delete "/logout", headers: {APIController::CSRF_HEADER => other_token}

        expect(status).to eq(403)
      end

      it "exempts safe (GET) cookie-authenticated requests from CSRF" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        get "/users/current-user"

        expect(status).to eq(200)
      end

      it "re-issues the XSRF-TOKEN cookie when it's missing on a cookie-authed request" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

        # simulate the XSRF cookie being cleared while the auth cookie persists
        cookies.delete(APIController::CSRF_COOKIE_NAME)

        delete "/logout"

        # the current request still fails CSRF (no header could be sent)...
        expect(status).to eq(403)
        # ...but the response includes a fresh XSRF cookie so the frontend can retry
        expect(response.cookies[APIController::CSRF_COOKIE_NAME]).to be_present
      end

      it "logout clears the XSRF-TOKEN cookie" do
        post "/login", params: {auth: {email: user.email, password: "Supersecret1"}}

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
        expect(response.headers["Set-Cookie"]).to include(a_string_starting_with("download_user=;"))
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
        post "/sessions/download-session?app=observations-tool",
          headers: authorize_headers(user.id, app: "observations-tool")

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

require "rails_helper"

module V1
  describe "Login and authenticate user", type: :request do
    it "Returns error object when the user cannot login" do
      post "/login", params: {auth: {email: user.email, password: "wrong password"}},
        headers: non_api_webuser_headers

      expect(status).to eq(401)
      expect(parsed_body).to eq({errors: [{status: 401, title: "Incorrect email or password"}]})
    end

    it "Valid login" do
      post "/login", params: {auth: {email: user.email, password: "Supersecret1"}},
        headers: non_api_webuser_headers

      expect(status).to eq(200)
      expect(parsed_body).to eq({
        token: JWT.encode({user: user.id}, ENV["AUTH_SECRET"], "HS256"),
        role: "user",
        user_id: user.id,
        country: nil, operator_ids: [], observer: nil
      })
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
          locale: nil,
          "organization-account": false,
          "permissions-request": nil,
          "permissions-accepted": nil,
          "managed-observer-ids": [],
          "qc1-observer-ids": [],
          "qc2-observer-ids": []
        })
      end

      it "Request without valid authorization for current user" do
        get "/users/current-user", headers: non_api_webuser_headers
        expect(parsed_body).to eq(default_status_errors(401))
      end
    end
  end
end

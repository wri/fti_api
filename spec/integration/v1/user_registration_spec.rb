require "rails_helper"

module V1
  describe "Register users", type: :request do
    let(:error) {
      {errors: [
        {status: 422, title: "password_confirmation can't be blank"}
      ]}
    }

    let(:error_pw) {
      {
        errors: [
          {status: 422, title: "password is too short (minimum is 10 characters)"},
          {status: 422, title: "password must contain at least one uppercase letter, one lowercase letter, and one digit"}
        ]
      }
    }

    let(:invalid_user_params) do
      {email: "test@gmail.com", password: "Password123", permissions_request: "government"}
    end

    let(:valid_user_params) do
      {
        email: "test@gmail.com",
        password: "Password123",
        password_confirmation: "Password123",
        locale: "en",
        permissions_request: "government",
        first_name: "First name",
        last_name: "Last name"
      }
    end

    describe "Registration" do
      it "Returns error object when the user cannot be registered" do
        post "/register", params: {user: invalid_user_params}, headers: non_api_webuser_headers

        expect(parsed_body).to eq(error)
        expect(status).to eq(422)
      end

      it "Returns error object when the user password is to short" do
        post("/register",
          params: {user: valid_user_params.merge(password: "121212", password_confirmation: "121212")},
          headers: non_api_webuser_headers)

        expect(parsed_body).to eq(error_pw)
        expect(status).to eq(422)
      end

      it "Register valid user" do
        expect {
          post "/register", params: {user: valid_user_params}, headers: non_api_webuser_headers
        }.to have_enqueued_mail(SystemMailer, :user_created)

        expect(parsed_body).to eq({messages: [{status: 201, title: "User successfully registered!"}]})
        expect(User.find_by(email: "test@gmail.com").locale).to eq("en")
        expect(status).to eq(201)
      end

      it "Register valid user with ngo role request" do
        expect {
          post("/register",
            params: {user: valid_user_params.merge(permissions_request: "ngo", observer_id: create(:observer).id)},
            headers: non_api_webuser_headers)
        }.to have_enqueued_mail(SystemMailer, :user_created)

        expect(parsed_body).to eq({messages: [{status: 201, title: "User successfully registered!"}]})
        expect(status).to eq(201)
        expect(User.find_by(email: "test@gmail.com").user_permission.user_role).to eq("ngo")
      end

      it "Returns error object when the user permissions_request invalid" do
        post("/register",
          params: {user: valid_user_params.merge(permissions_request: "invalid permissions_request")},
          headers: non_api_webuser_headers)

        expect(parsed_body).to eq({
          messages: [{
            status: 422,
            title: 'Not valid permissions_request. Valid permissions_request: ["operator", "ngo", "ngo_manager", "government"]'
          }]
        })
        expect(status).to eq(422)
      end
    end
  end
end

require "rails_helper"

module V1
  describe "Password", type: :request do
    let(:user) { create(:user, email: "test@email.com", password: "password", password_confirmation: "password", first_name: "00 User", last_name: "one") }

    context "Request reset password token" do
      describe "Valid request" do
        it "Request password reset token by user" do
          expect {
            post("/reset-password",
              params: {password: {email: user.email}},
              headers: non_api_webuser_headers)
          }.to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Reset password email sent if email in the database!"}]})
          expect(status).to eq(200)
        end
      end

      describe "Not valid request" do
        it "Returns 200 when the user email is not in the database" do
          expect {
            post("/reset-password",
              params: {password: {email: "invalid@gmai.com"}},
              headers: non_api_webuser_headers)
          }.not_to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Reset password email sent if email in the database!"}]})
          expect(status).to eq(200)
        end

        it "Returns 200 when object when the user email is not valid" do
          expect {
            post("/reset-password",
              params: {password: {any_attribute: ""}},
              headers: non_api_webuser_headers)
          }.not_to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Reset password email sent if email in the database!"}]})
          expect(status).to eq(200)
        end
      end
    end

    context "Reset password by token" do
      describe "Valid request" do
        let(:token) { user.send(:set_reset_password_token) }

        it "change user password" do
          post("/users/password",
            params: {password: {
              reset_password_token: token,
              password: "testpassword",
              password_confirmation: "testpassword"
            }},
            headers: non_api_webuser_headers)

          expect(parsed_body[:data][:attributes][:name]).to eq("00 User one")
          expect(parsed_body[:data][:attributes][:first_name]).to eq("00 User")
          expect(parsed_body[:data][:attributes][:last_name]).to eq("one")
          expect(parsed_body[:data][:attributes][:email]).to eq(user.email)
          expect(status).to eq(200)
        end
      end

      describe "Not valid request" do
        let(:invalid_token) { "invalid" }
        let(:valid_token) { user.send(:set_reset_password_token) }
        let(:expired_token) { travel_to(7.hours.ago) { user.send(:set_reset_password_token) } }
        let(:error_pw) { {errors: [{status: 422, title: "password_confirmation doesn't match Password"}]} }

        it "Returns error object when the user token is not valid" do
          post("/users/password",
            params: {password: {
              reset_password_token: invalid_token,
              password: "testpassword",
              password_confirmation: "testpassword"
            }},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq({errors: [{status: 422, title: "reset_password_token is invalid"}]})
          expect(status).to eq(422)
        end

        it "Returns error object when the user token is not present" do
          post("/users/password",
            params: {password: {password: "testpassword", password_confirmation: "testpassword"}},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq({errors: [{status: 422, title: "reset_password_token can't be blank"}]})
          expect(status).to eq(422)
        end

        it "Returns error object when the user password and confirmation not valid" do
          post("/users/password",
            params: {password: {reset_password_token: valid_token, password: "testpassword", password_confirmation: "testpass"}},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq(error_pw)
          expect(status).to eq(422)
        end

        it "Returns error object when the user token expired" do
          post("/users/password",
            params: {password: {reset_password_token: expired_token, password: "testpassword", password_confirmation: "testpassword"}},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq({errors: [{status: 422, title: "reset_password_token has expired, please request a new one"}]})
          expect(status).to eq(422)
        end
      end
    end
  end
end

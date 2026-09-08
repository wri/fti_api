require "rails_helper"

module V1
  describe "Password", type: :request do
    let(:user) { create(:user, email: "test@email.com", password: "Password123", password_confirmation: "Password123", first_name: "00 User", last_name: "one") }

    context "Request reset password token" do
      describe "Valid request" do
        it "Request password reset token by user" do
          expect {
            post("/reset-password",
              params: {password: {email: user.email}})
          }.to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Reset password email sent if email in the database!"}]})
          expect(status).to eq(200)
        end
      end

      describe "Not valid request" do
        it "Returns 200 when the user email is not in the database" do
          expect {
            post("/reset-password",
              params: {password: {email: "invalid@gmai.com"}})
          }.not_to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Reset password email sent if email in the database!"}]})
          expect(status).to eq(200)
        end
      end

      describe "Rate limiting" do
        def request_reset(email)
          post("/reset-password", params: {password: {email: email}})
        end

        it "Allows 3 password reset requests per IP per hour" do
          3.times do
            request_reset(user.email)
            expect(status).to eq(200)
          end
        end

        it "Throttles a 4th password reset request from the same IP" do
          3.times { request_reset(user.email) }

          request_reset("other@example.com")

          expect(status).to eq(429)
          expect(parsed_body).to eq({errors: [{status: 429, title: "Too many requests"}]})
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
              password: "Supersecret1",
              password_confirmation: "Supersecret1"
            }})

          expect(parsed_body[:data][:attributes][:name]).to eq("00 User one")
          expect(parsed_body[:data][:attributes][:"first-name"]).to eq("00 User")
          expect(parsed_body[:data][:attributes][:"last-name"]).to eq("one")
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
              password: "Supersecret1",
              password_confirmation: "Supersecret1"
            }})

          expect(parsed_body).to eq({errors: [{status: 422, title: "reset_password_token is invalid"}]})
          expect(status).to eq(422)
        end

        it "Returns error object when the user token is not present" do
          post("/users/password",
            params: {password: {password: "Supersecret1", password_confirmation: "Supersecret1"}})

          expect(parsed_body).to eq({errors: [{status: 422, title: "reset_password_token can't be blank"}]})
          expect(status).to eq(422)
        end

        it "Returns error object when the user password and confirmation not valid" do
          post("/users/password",
            params: {password: {reset_password_token: valid_token, password: "Supersecret1", password_confirmation: "Super"}})

          expect(parsed_body).to eq(error_pw)
          expect(status).to eq(422)
        end

        it "Returns error object when the user token expired" do
          post("/users/password",
            params: {password: {reset_password_token: expired_token, password: "Supersecret1", password_confirmation: "Supersecret1"}})

          expect(parsed_body).to eq({errors: [{status: 422, title: "reset_password_token has expired, please request a new one"}]})
          expect(status).to eq(422)
        end
      end

      describe "Rate limiting" do
        def reset_with_token(token)
          post("/users/password",
            params: {password: {
              reset_password_token: token,
              password: "Supersecret1",
              password_confirmation: "Supersecret1"
            }})
        end

        it "Allows 5 password reset-by-token attempts per IP per 15 minutes" do
          5.times do |i|
            reset_with_token("invalid-#{i}")
            expect(status).to eq(422)
          end
        end

        it "Throttles a 6th password reset-by-token attempt from the same IP" do
          5.times { |i| reset_with_token("invalid-#{i}") }

          reset_with_token(user.send(:set_reset_password_token))

          expect(status).to eq(429)
          expect(parsed_body).to eq({errors: [{status: 429, title: "Too many requests"}]})
        end
      end
    end
  end
end

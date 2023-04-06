require "rails_helper"

module V1
  describe "Password", type: :request do
    let(:user) { create(:user, email: "test@email.com", password: "password", password_confirmation: "password", name: "00 User one") }
    let(:user_2) { create(:user, email: "test2@email.com", password: "password", password_confirmation: "password", name: "00 User two") }

    context "Request reset password token" do
      describe "Valid request" do
        it "Request password reset token by user" do
          expect {
            post("/reset-password",
              params: {password: {email: user.email}},
              headers: non_api_webuser_headers)
          }.to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Reset password email sent!"}]})
          expect(status).to eq(200)
        end
      end

      describe "Not valid request" do
        it "Returns error object when the user email is not valid" do
          expect {
            post("/reset-password",
              params: {password: {email: "invalid@gmai.com"}},
              headers: non_api_webuser_headers)
          }.not_to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(parsed_body).to eq(default_status_errors("422_undefined_user"))
          expect(status).to eq(422)
        end

        it "Returns error object when the user email is not valid" do
          expect {
            post("/reset-password",
              params: {password: {any_attribute: ""}},
              headers: non_api_webuser_headers)
          }.not_to have_enqueued_mail(UserMailer, :forgotten_password)

          expect(status).to eq(422)
          expect(parsed_body).to eq(default_status_errors("422_undefined_user"))
        end
      end
    end

    context "Reset password by token" do
      describe "Valid request" do
        before(:each) do
          token = "9aa2da60-1f58-4c63-a765-282baf7a873c"
          user.update(reset_password_token: token, reset_password_sent_at: DateTime.now)
          user.reload
        end

        it "change user password" do
          post("/users/password",
            params: {password: {
              reset_password_token: "9aa2da60-1f58-4c63-a765-282baf7a873c",
              password: "testpassword",
              password_confirmation: "testpassword"
            }},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Password successfully updated!"}]})
          expect(status).to eq(200)
        end
      end

      describe "Not valid request" do
        before(:each) do
          @token = "9aa2da60-1f58-4c63-a765-282baf7a873c"
          @token_2 = "9aa2da60-1f58-4c63-a765-282baf7a8732"
          user.update(reset_password_token: @token, reset_password_sent_at: DateTime.now - 1.days)
          user_2.update(reset_password_token: @token_2, reset_password_sent_at: DateTime.now)
        end

        let(:error_pw) { {errors: [{status: 422, title: "password_confirmation doesn't match Password"}]} }
        let(:error_expired) { {errors: [{status: 422, title: "reset_password_token link expired."}]} }

        it "Returns error object when the user token is not valid" do
          post("/users/password",
            params: {password: {
              reset_password_token: "9aa2da60-1f58-4c63-a765-282baf7a873Q",
              password: "testpassword",
              password_confirmation: "testpassword"
            }},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq(default_status_errors("422_undefined_user"))
          expect(status).to eq(422)
        end

        it "Returns error object when the user token is not present" do
          post("/users/password",
            params: {password: {password: "testpassword", password_confirmation: "testpassword"}},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq(default_status_errors("422_undefined_user"))
          expect(status).to eq(422)
        end

        it "Returns error object when the user password and confirmation not valid" do
          post("/users/password",
            params: {password: {reset_password_token: @token_2, password: "testpassword", password_confirmation: "testpass"}},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq(error_pw)
          expect(status).to eq(422)
        end

        it "Returns error object when the user token expired" do
          post("/users/password",
            params: {password: {reset_password_token: @token, password: "testpassword", password_confirmation: "testpassword"}},
            headers: non_api_webuser_headers)

          expect(parsed_body).to eq(error_expired)
          expect(status).to eq(422)
        end
      end
    end

    context "Update user password" do
      let(:user_headers) { authorize_headers(user.id, jsonapi: false) }
      let(:error_pw) {
        {errors: [{status: 422, title: "password_confirmation doesn't match Password"},
          {status: 422, title: "password could not be updated!"}]}
      }

      describe "Current user can update password" do
        it "Returns error object when the user password and confirmation invalid" do
          patch("/users/current-user/password",
            params: {password: {password: "testpassword", password_confirmation: "testpass"}},
            headers: user_headers)

          expect(parsed_body).to eq(error_pw)
          expect(status).to eq(422)
        end

        it "Returns success object when the user password was updated" do
          patch("/users/current-user/password",
            params: {password: {password: "testpassword", password_confirmation: "testpassword"}},
            headers: user_headers)

          expect(parsed_body).to eq({messages: [{status: 200, title: "Password successfully updated!"}]})
          expect(status).to eq(200)
        end
      end
    end
  end
end

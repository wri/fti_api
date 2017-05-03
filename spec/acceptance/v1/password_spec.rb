require 'acceptance_helper'

module V1
  describe 'Password', type: :request do
    before(:each) do
      @webuser = create(:webuser)
      token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

      @headers = {
        "ACCEPT" => "application/json",
        "HTTP_OTP_API_KEY" => "Bearer #{token}"
      }
    end

    let!(:user)   { User.create(email: 'test@email.com',  password: 'password', password_confirmation: 'password', nickname: 'test', name: '00 User one') }
    let!(:user_2) { User.create(email: 'test2@email.com', password: 'password', password_confirmation: 'password', nickname: 'test2', name: '00 User two') }

    context 'Request reset password token' do
      describe 'Valid request' do
        it 'Request password reset token by user' do
          post '/reset-password', params: {"password": { "email": "test@email.com", "reset_url": "http://localhost:5000" }},
                                  headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Reset password email send!' }] }.to_json)
        end
      end

      describe 'Not valid request' do
        let!(:error) { { errors: [{ status: 422, title: "Unprocessable entity." }]}}

        it 'Returns error object when the user email is not valid' do
          post '/reset-password', params: {"password": { "email": "test@gmai.com", "reset_url": "http://localhost:5000" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns error object when the user email is not valid' do
          post '/reset-password', params: {"password": { "reset_url": "http://localhost:5000" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns error object when the user email is not valid' do
          post '/reset-password', params: {"password": { "reset_url": "http://localhost:5000" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end
      end
    end

    context 'Reset password by token' do
      describe 'Valid request' do
        before(:each) do
          token = '9aa2da60-1f58-4c63-a765-282baf7a873c'
          user.update(reset_password_token: token, reset_password_sent_at: DateTime.now)
          user.reload
        end

        it 'change user password' do
          post '/users/password', params: {"password": { "reset_password_token": "9aa2da60-1f58-4c63-a765-282baf7a873c", "password": "testpassword", "password_confirmation": "testpassword" }},
                                  headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Password successfully updated!' }] }.to_json)
        end
      end

      describe 'Not valid request' do
        before(:each) do
          @token   = '9aa2da60-1f58-4c63-a765-282baf7a873c'
          @token_2 = '9aa2da60-1f58-4c63-a765-282baf7a8732'
          user.update(reset_password_token: @token, reset_password_sent_at: DateTime.now - 1.days)
          user_2.update(reset_password_token: @token_2, reset_password_sent_at: DateTime.now)
        end

        let!(:error)         { { errors: [{ status: 422, title: "Unprocessable entity." }]}}
        let!(:error_pw)      { { errors: [{ status: 422, title: "password_confirmation doesn't match Password" }]}}
        let!(:error_expired) { { errors: [{ status: 422, title: "reset_password_token link expired." }]}}

        it 'Returns error object when the user token is not valid' do
          post  '/users/password', params: {"password": { "reset_password_token": "9aa2da60-1f58-4c63-a765-282baf7a873Q", "password": "testpassword", "password_confirmation": "testpassword" }},
                                   headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns error object when the user token is not present' do
          post  '/users/password', params: {"password": { "password": "testpassword", "password_confirmation": "testpassword" }},
                                   headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns error object when the user password and confirmation not valid' do
          post  '/users/password', params: {"password": { "reset_password_token": @token_2, "password": "testpassword", "password_confirmation": "testpass" }},
                                   headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error_pw.to_json)
        end

        it 'Returns error object when the user token expired' do
          post  '/users/password', params: {"password": { "reset_password_token": @token, "password": "testpassword", "password_confirmation": "testpassword" }},
                                   headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error_expired.to_json)
        end
      end
    end

    context 'Update user password' do
      let!(:error_pw) { { errors: [{ status: 422, title: "password_confirmation doesn't match Password" },
                                   { status: 422, title: "password could not be updated!" }]}}

      describe 'Current user can update password' do
        before(:each) do
          token    = JWT.encode({ user: user.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the user password and confirmation invalid' do
          patch '/users/current-user/password', params: {"password": { "password": "testpassword", "password_confirmation": "testpass" }},
                                                headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error_pw.to_json)
        end

        it 'Returns success object when the user password was updated' do
          patch '/users/current-user/password', params: {"password": { "password": "testpassword", "password_confirmation": "testpassword" }},
                                                headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Password successfully updated!' }] }.to_json)
        end
      end
    end
  end
end

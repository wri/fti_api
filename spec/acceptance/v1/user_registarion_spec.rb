require 'rails_helper'

module V1
  describe 'Register users', type: :request do
    let(:error) { { errors: [{ status: 422, title: "nickname can't be blank" },
                              { status: 422, title: "nickname is invalid"},
                              { status: 422, title: "name can't be blank"},
                              { status: 422, title: "password_confirmation can't be blank" }]}}

    let(:error_pw) { { errors: [{ status: 422, title: "password is too short (minimum is 8 characters)" }]}}

    let(:invalid_user_params) do
      { email: 'test@gmail.com', password: 'password', permissions_request: 'government' }
    end

    let(:valid_user_params) do
      {
        email: 'test@gmail.com',
        password: 'password',
        password_confirmation: 'password',
        permissions_request: 'government',
        nickname: 'sebanew',
        name: 'Test user new'
      }
    end

    describe 'Registration' do
      it 'Returns error object when the user cannot be registrated' do
        post '/register', params: { user: invalid_user_params }, headers: webuser_headers

        expect(parsed_body).to eq(error)
        expect(status).to eq(422)
      end

      it 'Returns error object when the user password is to short' do
        post('/register',
             params: { user: valid_user_params.merge(password: '12', password_confirmation: '12') },
             headers: webuser_headers)

        expect(parsed_body).to eq(error_pw)
        expect(status).to eq(422)
      end

      it 'Register valid user' do
        post '/register', params: { user: valid_user_params },
                          headers: webuser_headers

        expect(parsed_body).to eq({ messages: [{ status: 201, title: 'User successfully registered!' }] })
        expect(status).to eq(201)
      end

      it 'Register valid user with ngo role request' do
        post('/register',
             params: { user: valid_user_params.merge(permissions_request: 'ngo', observer_id: create(:observer).id) },
             headers: webuser_headers)

        expect(parsed_body).to eq({ messages: [{ status: 201, title: 'User successfully registered!' }] })
        expect(status).to eq(201)
        expect(User.find_by(email: 'test@gmail.com').user_permission.user_role).to eq('ngo')
      end

      it 'Returns error object when the user permissions_request invalid' do
        post('/register',
             params: { user: valid_user_params.merge(permissions_request: "invalid permissions_request") },
             headers: webuser_headers)

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

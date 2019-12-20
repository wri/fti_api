require 'rails_helper'

module V1
  describe 'Users', type: :request do
    it_behaves_like "jsonapi-resources", User, {
      show: {
        success_role: :admin
      },
      create: {
        success_role: :admin,
        failure_role: :user,
        excluded_params: %i[password password-confirmation permissions-request],
        valid_params: {
          email: 'test@gmail.com',
          nickname: 'sebanew',
          password: 'password',
          'password-confirmation': 'password',
          name: 'Test user new',
          'permissions-request': 'government'
        },
        invalid_params: { email: 'test@gmail.com', password: 'password', 'permissions-request': 'government' },
        error_attributes: [422, 100, {
          nickname: ["can't be blank", 'is invalid'],
          name: ["can't be blank"],
          'password-confirmation': ["can't be blank"],
        }]
      },
      edit: {
        success_role: :admin,
        failure_role: :user,
        excluded_params: %i[password password-confirmation permissions-request],
        valid_params: {
          email: 'test@gmail.com',
          nickname: 'sebanew',
          password: 'password',
          'password-confirmation': 'password',
          name: 'Test user new',
          'permissions-request': 'government'
        },
        invalid_params: { name: '', email: 'test@gmail.com', password: 'password', 'permissions-request': 'government' },
        error_attributes: [422, 100, { 'name': ["can't be blank"] }]
      },
      delete: {
        success_role: :admin,
        failure_role: :user
      },
      pagination: {
        success_role: :admin
      },
      sort: {
        success_role: :admin,
        attribute: :name,
        sequence: -> (i) { "#{i} observer" },
        expected_count: 8,
        desc: "Web user"
      }
    }    

    context 'Update users' do
      describe 'Update user by admin' do
        it "Can't update user role by admin" do
          patch("/users/#{user.id}",
                params: jsonapi_params('users', user.id, { 'permissions-request': 'ngo' }),
                headers: admin_headers)

          expect(status).to eq(200)
          expect(user.reload.ngo?).to eq(false)
        end
      end

      describe "Can't update profile" do
        it 'Returns error when update user by owner' do
          patch("/users/#{user.id}",
                params: jsonapi_params('users', user.id, { nickname: 'sebanew', name: 'Test user new' }),
                headers: user_headers)

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
        end

        it 'Do not allow user to change the role' do
          patch("/users/#{user.id}",
                params: jsonapi_params('users', user.id, { 'permissions-request': 'ngo' }),
                headers: user_headers)

          expect(status).to eq(401)
          expect(user.reload.ngo?).to eq(false)
        end
      end
    end
  end
end

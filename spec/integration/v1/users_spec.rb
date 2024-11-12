require "rails_helper"

module V1
  describe "Users", type: :request do
    it_behaves_like "jsonapi-resources", User, {
      show: {
        success_roles: %i[admin]
      },
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        excluded_params: %i[password password-confirmation permissions-request],
        valid_params: {
          email: "test@gmail.com",
          password: "Supersecret1",
          "password-confirmation": "Supersecret1",
          "first-name": "Test",
          "last-name": "user new",
          "permissions-request": "government"
        },
        invalid_params: {email: "test@gmail.com", password: "Supersecret1", "permissions-request": "government"},
        error_attributes: [422, 100, {
          "password-confirmation": ["can't be blank"]
        }]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        excluded_params: %i[password password-confirmation permissions-request current-password],
        valid_params: {
          email: "test@gmail.com",
          password: "NewPassword1",
          "password-confirmation": "NewPassword1",
          "current-password": "Supersecret1",
          "first-name": "Test",
          "last-name": "user new",
          "permissions-request": "government"
        },
        invalid_params: {email: "test@gmail.com", password: "Supersecret1", "password-confirmation": "Supersecret1", "permissions-request": "government"},
        error_attributes: [422, 100, {"current-password": ["can't be blank"]}]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {
        success_roles: %i[admin]
      }
    }

    context "Update users" do
      describe "Update user by admin" do
        it "Can't update user role by admin" do
          patch("/users/#{user.id}",
            params: jsonapi_params("users", user.id, {"permissions-request": "ngo"}),
            headers: admin_headers)

          expect(status).to eq(200)
          expect(user.reload.ngo?).to eq(false)
        end
      end

      describe "Can't update profile" do
        it "Returns error when update user by owner" do
          patch("/users/#{user.id}",
            params: jsonapi_params("users", user.id, {first_name: "Test user new"}),
            headers: user_headers)

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
        end

        it "Do not allow user to change the role" do
          patch("/users/#{user.id}",
            params: jsonapi_params("users", user.id, {"permissions-request": "ngo"}),
            headers: user_headers)

          expect(status).to eq(401)
          expect(user.reload.ngo?).to eq(false)
        end

        describe "Current Password validation" do
          it "requires current password when changing password" do
            patch("/users/#{operator_user.id}",
              params: jsonapi_params("users", operator_user.id, {password: "NewPassword1", "password-confirmation": "NewPassword1"}),
              headers: operator_user_headers)

            expect(status).to eq(422)
            expect(parsed_body[:errors].first[:detail]).to eq("current-password - can't be blank")
          end

          it "requires current password when changing email" do
            patch("/users/#{operator_user.id}",
              params: jsonapi_params("users", operator_user.id, {email: "newemail@example.com"}),
              headers: operator_user_headers)

            expect(status).to eq(422)
            expect(parsed_body[:errors].first[:detail]).to eq("current-password - can't be blank")
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module V1
  class PasswordsController < APIController
    skip_before_action :authenticate, only: [:create, :update]

    def create
      User.send_reset_password_instructions(create_params)
      render json: {messages: [{status: 200, title: "Reset password email sent if email in the database!"}]}, status: :ok
    end

    def update
      user = User.reset_password_by_token(update_params)
      if user.errors.empty?
        render json: JSONAPI::ResourceSerializer.new(
          UserResource,
          fields: {
            user: %w[name email]
          }
        ).serialize_to_hash(UserResource.new(user, context))
      else
        render_unprocessable_entity_error(user.errors)
      end
    end

    private

    def create_params
      params.require(:password).permit(:email)
    end

    def update_params
      params.require(:password).permit(:reset_password_token, :password, :password_confirmation)
    end
  end
end

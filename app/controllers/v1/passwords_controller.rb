# frozen_string_literal: true

module V1
  class PasswordsController < APIController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:create, :update_by_token]
    before_action :set_user

    def create
      if @user.errors.empty?
        @user.send_reset_password_instructions
        render json: {messages: [{status: 200, title: "Reset password email sent!"}]}, status: :ok
      else
        render json: ErrorSerializer.serialize(@user.errors, 422), status: :unprocessable_entity
      end
    end

    def update_by_token
      if @user.reset_password_by_token(user_params)
        if @user.errors.empty?
          render json: {messages: [{status: 200, title: "Password successfully updated!"}]}, status: :ok
        else
          render json: ErrorSerializer.serialize(@user.errors, 422), status: :unprocessable_entity
        end
      else
        render json: ErrorSerializer.serialize(@user.errors, 422), status: :unprocessable_entity
      end
    end

    def update
      if @user.reset_password_by_current_user(user_params)
        if @user.errors.empty?
          render json: {messages: [{status: 200, title: "Password successfully updated!"}]}, status: :ok
        else
          render json: ErrorSerializer.serialize(@user.errors, 422), status: :unprocessable_entity
        end
      else
        render json: ErrorSerializer.serialize(@user.errors, 422), status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = if logged_in?
        @current_user
      elsif user_params[:reset_password_token].present?
        User.find_by(reset_password_token: user_params[:reset_password_token])
      elsif user_params[:email].present?
        User.find_by(email: user_params[:email])
      end

      render json: {errors: [{status: 422, title: "Couldn't find the user with this email"}]}, status: :unprocessable_entity if @user.nil?
    end

    def user_params
      params.require(:password).permit(:email, :password, :password_confirmation, :reset_password_token, :reset_url)
    end
  end
end

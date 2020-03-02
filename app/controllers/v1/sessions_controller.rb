# frozen_string_literal: true

module V1
  class SessionsController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:create]

    def create
      @user = User.find_by(email: auth_params[:email])
      if @user&.valid_password?(auth_params[:password]) && @user&.is_active
        token = Auth.issue({ user: @user.id })
        @user.update_tracked_fields!(request)
        render json: { token: token, role: @user.user_permission.user_role,
                       user_id: @user.id, country: @user.country_id,
                       operator: @user.operator_id, observer: @user.observer_id }, status: :ok
      else
        render json: { errors: [{ status: '401', title: 'Incorrect email or password' }] }, status: :unauthorized
      end
    end

    private

    def auth_params
      params.require(:auth).permit(:email, :password, :current_sign_in_ip)
    end
  end
end

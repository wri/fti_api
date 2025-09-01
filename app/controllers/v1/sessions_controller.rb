# frozen_string_literal: true

module V1
  class SessionsController < APIController
    skip_before_action :authenticate, only: [:create]

    include ActionController::Cookies

    def create
      @user = User.find_by(email: auth_params[:email])
      if @user.present? && @user.valid_password?(auth_params[:password]) && @user.is_active
        token = Auth.issue({user: @user.id})
        @user.update_tracked_fields!(request)
        cookies.delete(download_user_cookie_name)
        render json: {token: token, role: @user.user_permission.user_role,
                      user_id: @user.id, country: @user.country_id,
                      operator_ids: @user.operator_ids, observer: @user.observer_id}, status: :ok
      else
        render json: {errors: [{status: 401, title: "Incorrect email or password"}]}, status: :unauthorized
      end
    end

    def destroy
      cookies.delete(download_user_cookie_name)
    end

    # each app, like portal and observation tool can have it's own download user cookie to prevent some edgecases
    def download_session
      download_token = Rails.application.message_verifier("download_token").generate(
        {user_id: current_user.id},
        expires_in: 10.minutes
      )
      cookies[download_user_cookie_name] = {
        value: download_token,
        expires: 10.minutes.from_now,
        same_site: :strict,
        secure: Rails.env.production? || Rails.env.staging?,
        httponly: true
      }
      head :ok
    end

    private

    def auth_params
      params.require(:auth).permit(:email, :password, :current_sign_in_ip)
    end

    def download_user_cookie_name
      [context[:app], "download_user"].compact.join("_")
    end
  end
end

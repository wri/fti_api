# frozen_string_literal: true

module V1
  class SessionsController < APIController
    skip_before_action :authenticate, only: [:create]

    include ActionController::Cookies

    # how long the auth cookie stays valid server-side. The default is a browser
    # session cookie (dropped on browser close) capped at SESSION_TTL so a
    # captured cookie can't be replayed indefinitely; remember_me persists the
    # cookie across restarts for REMEMBER_ME_TTL.
    SESSION_TTL = 24.hours
    REMEMBER_ME_TTL = 30.days

    def create
      @user = User.find_by(email: auth_params[:email])
      if @user.present? && @user.valid_password?(auth_params[:password]) && @user.is_active
        token = Auth.issue({user: @user.id})
        @user.update_column(:should_change_password, true) unless User.strong_password?(auth_params[:password])
        @user.update_tracked_fields!(request)
        set_download_session_cookie_for(@user)
        set_auth_cookie(@user) if ActiveModel::Type::Boolean.new.cast(auth_params[:set_cookie])
        render json: {token: token, role: @user.user_permission.user_role,
                      user_id: @user.id, country: @user.country_id,
                      operator_ids: @user.operator_ids, observer: @user.observer_id}, status: :ok
      else
        render json: {errors: [{status: 401, title: "Incorrect email or password"}]}, status: :unauthorized
      end
    end

    def destroy
      cookies.delete(download_user_cookie_name)
      cookies.delete(auth_cookie_name)
    end

    # each app, like portal and observation tool can have it's own download user cookie to prevent some edgecases
    def download_session
      set_download_session_cookie_for(current_user)
      head :ok
    end

    private

    def auth_params
      params.expect(auth: [:email, :password, :current_sign_in_ip, :set_cookie, :remember_me])
    end

    def set_auth_cookie(user)
      ttl = remember_me? ? REMEMBER_ME_TTL : SESSION_TTL
      cookie = {
        value: {user_id: user.id, exp: ttl.from_now.to_i},
        same_site: :strict,
        secure: Rails.env.production? || Rails.env.staging?,
        httponly: true
      }
      # remember_me makes the browser persist the cookie across restarts;
      # otherwise it stays a session cookie but is still capped server-side by
      # the exp baked into the encrypted payload above
      cookie[:expires] = ttl.from_now if remember_me?
      cookies.encrypted[auth_cookie_name] = cookie
    end

    def remember_me?
      ActiveModel::Type::Boolean.new.cast(auth_params[:remember_me])
    end

    def set_download_session_cookie_for(user)
      download_token = Rails.application.message_verifier("download_token").generate(
        {user_id: user.id},
        expires_in: 10.minutes
      )
      cookies[download_user_cookie_name] = {
        value: download_token,
        expires: 10.minutes.from_now,
        same_site: :strict,
        secure: Rails.env.production? || Rails.env.staging?,
        httponly: true
      }
    end

    def download_user_cookie_name
      [context[:app], "download_user"].compact.join("_")
    end
  end
end

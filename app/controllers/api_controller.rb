# frozen_string_literal: true

require "oj"
require "auth"

class APIController < ActionController::API
  include ActionController::Cookies
  include CanCan::ControllerAdditions
  include JSONAPI::ActsAsResourceController
  include CsrfProtection

  AUTH_COOKIE_NAME = "otp_auth_token"

  def context
    {current_user: current_user,
     app: params[:app],
     action: params[:action],
     controller: params[:controller],
     filters: params[:filter],
     locale: params[:locale] || I18n.default_locale}
  end

  before_action :authenticate
  before_action :set_paper_trail_whodunnit
  around_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::RoutingError, with: :record_not_found
  rescue_from JWT::VerificationError, with: :bad_auth_key

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug { "Access denied on #{exception.action} #{exception.subject.inspect}" }
    render json: {errors: [{status: 401, title: exception.message}]}, status: :unauthorized
  end

  on_server_error do |error|
    Sentry.capture_exception(error)
  end

  def logged_in?
    !!current_user
  end

  def current_user
    @current_user ||= begin
      id = user_id_from_token
      user = User.find_by(id: id) if id
      user if user&.is_active
    end
  rescue
    @current_user = nil
  end

  def user_for_paper_trail
    current_user&.id
  end

  protected

  def authenticate
    render json: {errors: [{status: 401, title: "You are not authorized to access this page."}]}, status: :unauthorized unless logged_in?
  end

  def record_not_found
    render json: {errors: [{status: 404, title: "Record not found"}]}, status: :not_found
  end

  def render_unprocessable_entity_error(errors)
    json_errors = {errors: []}

    errors.messages.each do |err_type, messages|
      messages.each do |msg|
        json_errors[:errors] << {status: 422, title: "#{err_type} #{msg}"}
      end
    end

    render json: json_errors, status: :unprocessable_content
  end

  # Resolve the authenticated user id from either the Bearer JWT (API clients)
  # or the encrypted session cookie set at login. The Bearer header takes
  # precedence so an explicit token always wins over a stored cookie.
  def user_id_from_token
    user_id_from_bearer_token || user_id_from_auth_cookie
  end

  def user_id_from_bearer_token
    return unless bearer_token.present?

    Auth.decode(bearer_token)&.dig("user")
  end

  # The cookie is encrypted with the app's secret_key_base (opaque, tamper-proof)
  # rather than a JWT, so its payload is not readable by the client. For
  # remember_me logins Rails embeds a server-verified expiry into the payload
  # via use_cookies_with_metadata; the default browser-session cookie has no
  # server-side expiry and is dropped client-side when the browser closes.
  def user_id_from_auth_cookie
    cookies.encrypted[auth_cookie_name]
  end

  # each app, like portal and observations tool, has its own auth cookie so a
  # user can be logged into both at the same time. portal (no app param) uses
  # the bare name, observations-tool gets an "observations-tool_" prefix.
  def auth_cookie_name
    [params[:app], AUTH_COOKIE_NAME].compact.join("_")
  end

  def bearer_token
    request.env["HTTP_AUTHORIZATION"]&.scan(/Bearer (.*)$/)&.flatten&.last
  end

  def bad_auth_key
    render json: {errors: [{status: 400, title: "API Key/Authorization Key mal formed"}]}, status: :bad_request
  end

  def set_locale(&action)
    locale = if params[:locale].present? && I18n.available_locales.map { |x| x.to_s }.include?(params[:locale])
      params[:locale]
    else
      I18n.default_locale.to_s
    end
    I18n.with_locale(locale, &action)
  end
end

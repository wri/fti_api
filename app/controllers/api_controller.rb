# frozen_string_literal: true

require "oj"

class APIController < ActionController::API
  class UnprocessableContentError < StandardError; end

  include ActionController::Cookies
  include CanCan::ControllerAdditions
  include JSONAPI::ActsAsResourceController
  include CrossOriginReporting
  include CsrfProtection

  AUTH_COOKIE_NAME = "otp_auth_token"
  # frontends allowed to namespace their own cookies and scope resources via ?app=
  APPS = %w[observations-tool].freeze

  def context
    {current_user: current_user,
     app: app_name,
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
  rescue_from UnprocessableContentError, with: :unprocessable_content

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
      user = auth_cookie_user
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

  def unprocessable_content(exception)
    render json: {errors: [{status: 422, title: exception.message}]}, status: :unprocessable_content
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

  # The cookie is encrypted with the app's secret_key_base, so it is opaque and
  # tamper-proof and its payload is not readable by the client. For
  # remember_me logins Rails embeds a server-verified expiry into the payload
  # via use_cookies_with_metadata; the default browser-session cookie has no
  # server-side expiry and is dropped client-side when the browser closes.
  #
  # The payload pairs the user id with their authenticatable_salt (derived from
  # the password digest), so changing a password invalidates every cookie issued
  # before it without needing a server-side session store.
  def auth_cookie_user
    return @auth_cookie_user if defined?(@auth_cookie_user)

    @auth_cookie_user = begin
      id, salt = cookies.encrypted[auth_cookie_name]
      user = User.find_by(id: id) if id
      user if user && ActiveSupport::SecurityUtils.secure_compare(salt.to_s, user.authenticatable_salt.to_s)
    end
  end

  # each app, like portal and observations tool, has its own auth cookie so a
  # user can be logged into both at the same time. portal (no app param) uses
  # the bare name, observations-tool gets an "observations-tool_" prefix.
  def auth_cookie_name
    [app_name, AUTH_COOKIE_NAME].compact.join("_")
  end

  # unknown values fall back to the portal, so a caller can't have an arbitrary
  # param decide which cookie authenticates them or what a resource scopes to
  def app_name
    params[:app].presence_in(APPS)
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

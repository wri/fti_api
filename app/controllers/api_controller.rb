# frozen_string_literal: true

require "oj"
require "auth"

class APIController < ActionController::API
  include CanCan::ControllerAdditions
  include JSONAPI::ActsAsResourceController

  def context
    {current_user: current_user,
     app: params[:app],
     action: params[:action],
     controller: params[:controller],
     filters: params[:filter],
     locale: (params[:locale] || I18n.default_locale)}
  end

  before_action :check_access, :authenticate
  before_action :set_paper_trail_whodunnit
  around_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::RoutingError, with: :record_not_found
  rescue_from JWT::VerificationError, with: :bad_auth_key

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    render json: {errors: [{status: "401", title: exception.message}]}, status: :unauthorized
  end

  on_server_error do |error|
    Sentry.capture_exception(error)
  end

  def valid_api_key?
    !!web_user
  end

  def logged_in?
    !!current_user
  end

  def web_user
    if api_key_present?
      user = User.find(api_auth["user"])
      if user&.api_key_exists?
        @current_api_user ||= user
      end
    end
  rescue
    @current_api_user = nil
  end

  def current_user
    if auth_present?
      user = User.find(auth["user"])
      if user&.is_active
        @current_user ||= user
      end
    end
  rescue
    @current_user = nil
  end

  def user_for_paper_trail
    current_user&.id
  end

  protected

  def check_access
    render json: {errors: [{status: "401", title: "Sorry invalid API token"}]}, status: :unauthorized unless valid_api_key?
  end

  def authenticate
    render json: {errors: [{status: "401", title: "You are not authorized to access this page."}]}, status: :unauthorized unless logged_in?
  end

  def record_not_found
    render json: {errors: [{status: "404", title: "Record not found"}]}, status: :not_found
  end

  def token
    request.env["HTTP_AUTHORIZATION"].scan(/Bearer (.*)$/).flatten.last
  end

  def api_key
    request.env["HTTP_OTP_API_KEY"].scan(/Bearer (.*)$/).flatten.last
  end

  def auth
    Auth.decode(token)
  end

  def api_auth
    Auth.decode(api_key)
  end

  def api_key_present?
    !!request.env.fetch("HTTP_OTP_API_KEY", "").scan(/Bearer/).flatten.first
  end

  def auth_present?
    !!request.env.fetch("HTTP_AUTHORIZATION", "").scan(/Bearer/).flatten.first
  end

  def bad_auth_key
    render json: {errors: [{status: "400", title: "API Key/Authorization Key mal formed"}]}, status: :bad_request
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

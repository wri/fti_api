# frozen_string_literal: true


class ApplicationController < ActionController::Base
  protect_from_forgery

  # Active admin permissions
  def authenticate_user!
    if current_user.present?
      unless current_user.user_permission.present? &&
          %w(admin bo_manager).include?(current_user.user_permission.user_role) &&
          current_user.is_active
        raise SecurityError
      end
    else
      redirect_to user_session_path
    end
  end

  rescue_from SecurityError do
    redirect_to destroy_user_session_path
  end

  def access_denied(exception)
    redirect_to admin_dashboard_path, alert: exception.message
  end

  def set_admin_locale
    I18n.locale = :en
  end
end

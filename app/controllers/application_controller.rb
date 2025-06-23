# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include FilterSaver

  before_action :exclude_whodunnit_from_login
  before_action :restore_search_filters, unless: :devise_controller?
  after_action :save_search_filters, unless: :devise_controller?

  protect_from_forgery

  # Active admin permissions
  def authenticate_user!
    raise SecurityError if current_user.present? && !backoffice_user?

    super
  end

  rescue_from SecurityError do
    redirect_to destroy_user_session_path
  end

  def access_denied(exception)
    redirect_to admin_dashboard_path, alert: exception.message
  end

  def set_admin_locale
    I18n.locale = current_user&.locale&.presence || :en
  end

  protected

  def exclude_whodunnit_from_login
    return if request.fullpath == "/admin/login"

    set_paper_trail_whodunnit
  end

  def user_for_paper_trail
    user_signed_in?.present? ? current_user.try(:id) : "Unknown user"
  end

  private

  def backoffice_user?
    current_user.user_permission.present? && current_user.is_active &&
      %w[admin bo_manager].include?(current_user.user_permission.user_role)
  end
end

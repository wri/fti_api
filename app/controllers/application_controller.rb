# frozen_string_literal: true


class ApplicationController < ActionController::Base

  # Active admin permissions
  def authenticate_user!
    if current_user.present?
      unless current_user.user_permission.present? && current_user.user_permission.user_role == 'admin' && current_user.is_active
        raise SecurityError
      end
    else
      redirect_to user_session_path
    end
  end

  rescue_from SecurityError do
    redirect_to destroy_user_session_path
  end
end

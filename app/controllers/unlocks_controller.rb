# frozen_string_literal: true

class UnlocksController < ApplicationController
  def show
    user = User.unlock_access_by_token(params[:unlock_token].to_s)

    if user.errors.empty?
      redirect_to after_unlock_url(user), allow_other_host: true, notice: I18n.t("devise.unlocks.unlocked")
    else
      redirect_to ENV.fetch("FRONTEND_URL"), allow_other_host: true
    end
  end

  private

  def after_unlock_url(user)
    if user.admin? || user.bo_manager?
      new_user_session_path
    elsif user.observation_tool_user?
      ENV.fetch("OBSERVATIONS_TOOL_URL")
    else
      ENV.fetch("FRONTEND_URL")
    end
  end
end

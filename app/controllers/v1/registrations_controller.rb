# frozen_string_literal: true

module V1
  class RegistrationsController < APIController
    include ErrorSerializer

    skip_before_action :authenticate
    before_action :reject_params

    def create
      @user = User.new(user_params)
      @user.is_active = false
      if @user.save
        SystemMailer.user_created(@user).deliver_later
        render json: { messages: [{ status: 201, title: 'User successfully registered!' }] }, status: :created
      else
        render json: ErrorSerializer.serialize(@user.errors, 422), status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation,
                                   :permissions_request, :country_id, :observer_id, :operator_id).tap do |user_params|
        user_params[:permissions_request] = params[:user][:permissions_request].downcase if params[:user][:permissions_request].present?
      end
    end

    def reject_params
      if params[:user][:permissions_request].present?
        permissions = params[:user][:permissions_request].downcase
        unless permissions.in?(User::PERMISSIONS)
          render json: { messages: [{ status: 422, title: "Not valid permissions_request. Valid permissions_request: #{User::PERMISSIONS}" }] }, status: :unprocessable_entity
        end
      end
    end
  end
end

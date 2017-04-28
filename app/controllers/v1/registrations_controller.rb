# frozen_string_literal: true

module V1
  class RegistrationsController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate
    before_action :reject_params

    def create
      @user = User.new(user_params)
      if @user.save
        render json: { messages: [{ status: 201, title: 'User successfully registrated!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@user.errors, 422), status: 422
      end
    end

    private

      def user_params
        params.require(:user).permit(:name, :nickname, :email, :password, :password_confirmation, :permissions_request, :country_id, :institution).tap do |user_params|
          user_params[:permissions_request] = params[:user][:permissions_request].downcase if params[:user][:permissions_request].present?
        end
      end

      def reject_params
        if params[:user][:permissions_request].present?
          permissions = params[:user][:permissions_request].downcase
          unless permissions.in?(User::PERMISSIONS)
            render json: { messages: [{ status: 422, title: "Not valid permissions_request. Valid permissions_request: #{User::PERMISSIONS}" }] }, status: 422
          end
        end
      end
  end
end

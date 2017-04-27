# frozen_string_literal: true

module V1
  class RegistrationsController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate

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
          user_params[:permissions_request] = params[:user][:permissions_request].downcase
        end
      end
  end
end

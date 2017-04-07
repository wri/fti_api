# frozen_string_literal: true

module V1
  class SessionsController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:create]

    def create
      @user = User.find_by(email: auth_params[:email])
      if @user && @user.authenticate(auth_params[:password])
        token = Auth.issue({ user: @user.id })
        render json: { token: token }
      else
        render json: { errors: [{ status: '401', title: 'Incorrect email or password' }] }, status: 401
      end
    end

    private

      def auth_params
        params.require(:auth).permit(:email, :password)
      end
  end
end

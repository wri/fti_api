# frozen_string_literal: true

module V1
  class CurrentUserController < ApplicationController
    include ErrorSerializer

    def show
      render json: current_user, include: ['user_permission'], serializer: UserSerializer
    end
  end
end

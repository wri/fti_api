# frozen_string_literal: true

module V1
  class UsersController < ApiController
    include ErrorSerializer

    load_and_authorize_resource class: 'User'

    def update
      # this is temporary thing allow transition for observation tool
      if context[:app] == 'observations-tool' && !update_params[:current_password]
        super
      else
        user = User.find(context[:current_user])
        if user.send(update_action, update_params)
          render json: JSONAPI::ResourceSerializer.new(
            UserResource
          ).serialize_to_hash(UserResource.new(user, context))
        else
          render json: ErrorSerializer.serialize(user.errors, 422), status: :unprocessable_entity
        end
      end
    end

    def current
      user = User.find(context[:current_user])
      include_resources = %w[user_permission observer operator country observer.country]
      render json: JSONAPI::ResourceSerializer.new(
        UserResource,
        include: include_resources
      ).serialize_to_hash(UserResource.new(user, context))
    end

    private

    def update_action
      return "update_with_password" if update_params[:password]

      "update"
    end

    def update_params
      params
        .require(:data)
        .require(:attributes)
        .permit(
          :password,
          :password_confirmation,
          :current_password,
          :name,
          :nickname,
          :email,
          :locale,
        )
    end
  end
end

# frozen_string_literal: true

module V1
  class UsersController < APIController
    load_and_authorize_resource class: "User"

    def update
      user = User.find(params[:id])
      if user.send(update_action, update_params)
        render json: JSONAPI::ResourceSerializer.new(
          UserResource
        ).serialize_to_hash(UserResource.new(user, context))
      else
        # to keep JSONAPI style validation errors, using that jsonapi-resources method
        handle_exceptions(JSONAPI::Exceptions::ValidationErrors.new(UserResource.new(user, context)))
      end
    end

    def current
      user = User.find(context[:current_user].id)
      include_resources = %w[user_permission observer managed_observers operator country observer.country]
      render json: JSONAPI::ResourceSerializer.new(
        UserResource,
        include: include_resources
      ).serialize_to_hash(UserResource.new(user, context))
    end

    private

    def update_action
      return "update_with_password" if validate_current_password?

      "update"
    end

    def validate_current_password?
      update_params[:password] || update_params[:email]
    end

    def update_params
      p = params
        .require(:data)
        .require(:attributes)
        .permit(
          :password,
          :"password-confirmation",
          :"current-password",
          :"first-name",
          :"last-name",
          :"organization-account",
          :name,
          :email,
          :locale
        )
      # better in this way to keep actioncontroller::parameters object, this rails version has some bugs
      p.transform_keys!(&:underscore)
      p
    end
  end
end

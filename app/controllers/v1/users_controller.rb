# frozen_string_literal: true

module V1
  class UsersController < ApiController
    include ErrorSerializer

    load_and_authorize_resource class: 'User'

    def update
      # this is temporary thing allow transition for observation tool
      if use_json_api_resources?
        super
      else
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
    end

    def current
      user = User.find(context[:current_user].id)
      include_resources = %w[user_permission observer operator country observer.country]
      render json: JSONAPI::ResourceSerializer.new(
        UserResource,
        include: include_resources
      ).serialize_to_hash(UserResource.new(user, context))
    end

    private

    def use_json_api_resources?
      context[:app] == 'observations-tool' && !update_params[:current_password]
    end

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
          :'password-confirmation',
          :'current-password',
          :name,
          :nickname,
          :email,
          :locale,
        )
      # better in this way to keep actioncontroller::parameters object, this rails version has some bugs
      p.transform_keys!(&:underscore)
      p
    end
  end
end

# frozen_string_literal: true

module V1
  class UsersController < ApiController
    include ErrorSerializer

    load_and_authorize_resource class: 'User'

    def current
      user = User.find(context[:current_user])
      include_resources = %w[user_permission observer operator country observer.country]
      render json: JSONAPI::ResourceSerializer.new(UserResource,
                                                   include: include_resources).serialize_to_hash(UserResource.new(user, context))
    end
  end
end

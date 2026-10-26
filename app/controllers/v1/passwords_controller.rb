# frozen_string_literal: true

module V1
  class PasswordsController < APIController
    include AuthRateLimiting

    skip_before_action :authenticate, only: [:create, :update]

    # email bucket stops inbox-bombing one address; IP bucket stops one client
    # mailing many addresses. Keyed by email so users behind a shared IP don't collide.
    rate_limit to: 3, within: 1.hour, only: :create,
      by: -> { reset_email_key },
      with: -> { render_too_many_requests },
      store: AuthRateLimiting::STORE,
      name: "request-email"
    rate_limit to: 20, within: 1.hour, only: :create,
      by: -> { request.remote_ip },
      with: -> { render_too_many_requests },
      store: AuthRateLimiting::STORE,
      name: "request-ip"
    # reset tokens are unguessable; this only caps hammering from one client
    rate_limit to: 30, within: 15.minutes, only: :update,
      by: -> { request.remote_ip },
      with: -> { render_too_many_requests },
      store: AuthRateLimiting::STORE,
      name: "reset"

    def create
      User.send_reset_password_instructions(create_params)
      render json: {messages: [{status: 200, title: "Reset password email sent if email in the database!"}]}, status: :ok
    end

    def update
      user = User.reset_password_by_token(update_params)
      if user.errors.empty?
        render json: JSONAPI::ResourceSerializer.new(
          UserResource,
          fields: {
            user: %w[name email]
          }
        ).serialize_to_hash(UserResource.new(user, context))
      else
        render_unprocessable_entity_error(user.errors)
      end
    end

    private

    def create_params
      params.expect(password: [:email])
    end

    def reset_email_key
      params.dig(:password, :email).to_s.downcase.strip.presence || request.remote_ip
    end

    def update_params
      params.expect(password: [:reset_password_token, :password, :password_confirmation])
    end
  end
end

require 'rails_helper'

module Helpers
  module Acceptance
    def json
      @json ||= parsed_body[:data]
    end

    def json_attr
      @json_attr ||= json[:attributes]
    end

    def parsed_body
      @parsed_body ||= Oj.load(response.body, symbol_keys: true)
    end

    def login_user(user)
      post '/login', params: {"auth": { "email": "#{user.email}", "password": "#{user.password}" }}
    end

    def generate_token(id)
      JWT.encode({ user: id }, ENV['AUTH_SECRET'], 'HS256')
    end

    def webuser
      @webuser ||= create(:webuser)
    end

    def webuser_token
      @webuser_token ||= generate_token(webuser.id)
    end

    def webuser_headers
      @webuser_headers ||= { "HTTP_OTP_API_KEY" => "Bearer #{webuser_token}" }
    end

    def authorize_headers(id, jsonapi: false)
      headers = webuser_headers.merge(
        "Authorization" => "Bearer #{generate_token(id)}"
      )

      return headers unless jsonapi

      headers.merge(
        "Content-Type" => "application/vnd.api+json",
        "HTTP_ACCEPT" => "application/vnd.api+json",
      )
    end
  end
end

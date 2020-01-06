require 'acceptance_helper'

module V1
  describe 'Donor', type: :request do
    it_behaves_like "jsonapi-resources", Donor, {
      success_headers: {
        'Content-Type' => 'application/vnd.api+json',
        'HTTP_ACCEPT' => 'application/vnd.api+json',
        "HTTP_OTP_API_KEY" => "Bearer #{JWT.encode({ user: create(:webuser).id }, ENV['AUTH_SECRET'], 'HS256')}",
        'Authorization' => "Bearer #{JWT.encode({ user: create(:admin).id }, ENV['AUTH_SECRET'], 'HS256')}",
      },
      locales: {
        en: {
          expected: {}
        },
        fr: {
          expected: {}
        }
      }
    }
  end
end

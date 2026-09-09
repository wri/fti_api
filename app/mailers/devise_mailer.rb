# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  layout "mailer"

  # Devise's unlock_url helper forwards the user into user_unlock_url, which
  # Rails treats as a format on our GET /unlock route (/unlock.123).
  helper do
    def unlock_url(_resource, unlock_token: nil, **)
      user_unlock_url(unlock_token: unlock_token)
    end
  end
end

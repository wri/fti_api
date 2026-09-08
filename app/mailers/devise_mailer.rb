# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  include Rails.application.routes.url_helpers

  def unlock_url(_resource, opts = {})
    user_unlock_url(opts)
  end
end

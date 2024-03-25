# frozen_string_literal: true

require "active_support/core_ext/integer/time"
require_relative "production"

Rails.application.configure do
  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.show_previews = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :letter_opener_web
end

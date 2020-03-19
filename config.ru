# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

# rubocop:disable Lint/RescueException:
begin
  require_relative 'config/environment'
rescue Exception => e
  Appsignal.send_error(e)
  raise
end
# rubocop:enable Lint/RescueException:

run Rails.application

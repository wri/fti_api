# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout "mailer"
  prepend_view_path "app/views/mailers"
  default from: ENV["CONTACT_EMAIL"]
end

# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'no-replay@vizzuality.com'
  layout 'mailer'
end

# frozen_string_literal: true

class AsyncMailer < ApplicationMailer
  include Resque::Mailer
  Resque::Mailer.excluded_environments = [:development, :test]
end

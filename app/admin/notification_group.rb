# frozen_string_literal: true

ActiveAdmin.register NotificationGroup do
  extend BackRedirectable
  back_redirect

  menu false

  permit_params :days, :name
end

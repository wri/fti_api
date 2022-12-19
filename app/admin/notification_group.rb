# frozen_string_literal: true

ActiveAdmin.register NotificationGroup do
  extend BackRedirectable

  menu false

  permit_params :days, :name
end

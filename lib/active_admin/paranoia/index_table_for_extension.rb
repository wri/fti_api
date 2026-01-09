# frozen_string_literal: true

# base for this module taken from https://github.com/raihan2006i/active_admin_paranoia

module ActiveAdmin
  module Paranoia
    module IndexTableForExtension
      def defaults(resource, options = {})
        if resource.respond_to?(:deleted?) && resource.deleted?
          if controller.action_methods.include?("restore") && authorized?(:restore, resource)
            # TODO: find a way to use the correct path helper
            item I18n.t("active_admin_paranoia.restore"), "#{resource_path(resource)}/restore", method: :put, class: "restore_link #{options[:css_class]}",
              data: {confirm: I18n.t("active_admin_paranoia.restore_confirmation")}
          end
        else
          super
        end
      end
    end
  end
end

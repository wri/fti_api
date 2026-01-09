# frozen_string_literal: true

# base for this module taken from https://github.com/raihan2006i/active_admin_paranoia

module ActiveAdmin
  module Paranoia
    module DSLExtension
      def active_admin_paranoia(scopes: true)
        controller do
          def find_resource # rubocop:disable Lint/NestedMethodDefinition
            resource_class.to_s.camelize.constantize.with_deleted.public_send(method_for_find, params[:id])
          end
        end

        action_item :restore, only: :show, if: proc { resource.paranoia_destroyed? } do
          link_to(I18n.t("active_admin_paranoia.restore_model", model: resource_class.to_s.titleize), "#{resource_path(resource)}/restore", method: :put, data: {confirm: I18n.t("active_admin_paranoia.restore_confirmation")}) if authorized?(:restore, resource)
        end

        member_action :restore, method: :put, confirm: proc { I18n.t("active_admin_paranoia.restore_confirmation") }, if: proc { authorized?(:restore, resource_class) } do
          resource.restore(recursive: true)
          options = {notice: I18n.t("active_admin_paranoia.batch_actions.succesfully_restored", count: 1, model: resource_class.to_s.camelize.constantize.model_name, plural_model: resource_class.to_s.downcase.pluralize)}

          redirect_back_or_to(ActiveAdmin.application.root_to, **options)
        end

        if scopes
          scope -> { I18n.t("active_admin_paranoia.non_archived") }, :non_archived, default: true do |scope|
            scope.where(resource_class.to_s.camelize.constantize.paranoia_column => resource_class.to_s.camelize.constantize.paranoia_sentinel_value)
          end
          scope -> { I18n.t("active_admin_paranoia.archived") }, :archived do |scope|
            scope.unscope(where: resource_class.to_s.camelize.constantize.paranoia_column).where.not(resource_class.to_s.camelize.constantize.paranoia_column => resource_class.to_s.camelize.constantize.paranoia_sentinel_value)
          end
        end
      end
    end
  end
end

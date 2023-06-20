# frozen_string_literal: true

ActiveAdmin.register UserPermission do
  menu false

  actions :update
  permit_params permissions:
                    [fmu: [manage: {}, read: {}],
                     law: [manage: {}, read: {}],
                     user: [manage: {}, read: {}],
                     species: [manage: {}, read: {}],
                     category: [manage: {}, read: {}],
                     observer: [manage: {}, read: {}],
                     operator: [manage: {}, read: {}],
                     severity: [manage: {}, read: {}],
                     government: [manage: {}, read: {}],
                     observation: [manage: {}, read: {}],
                     subcategory: [manage: {}, read: {}],
                     operator_document: [manage: {}, read: {}],
                     observation_report: [manage: {}, read: {}],
                     observation_documents: [manage: {}, read: {}],
                     required_operator_document: [manage: {}, read: {}],
                     required_operator_document_group: [manage: {}, read: {}]]

  controller do
    def update
      if params["user_permission"].present? && params["user_permission"]["permissions"].present?
        parsed_permissions = params["user_permission"]["permissions"].to_s
        parsed_permissions = JSON.parse(parsed_permissions)
        params["user_permission"]["permissions"] = parsed_permissions
      end
      super do
        redirect_to admin_access_control_path, notice: I18n.t("active_admin.shared.permissions_changed") and return if resource.valid?
      end
    end
  end
end

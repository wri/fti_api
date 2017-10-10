# frozen_string_literal: true

# == Schema Information
#
# Table name: user_permissions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  user_role   :integer          default("user"), not null
#  permissions :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class UserPermission < ApplicationRecord
  enum user_role: { user: 0, operator: 1, ngo: 2, ngo_manager: 4, bo_manager: 5, admin: 3 }.freeze

  belongs_to :user

  before_create :change_permissions
  before_update :change_permissions,         if: 'user_role_changed?'

  def change_permissions
    self.permissions = role_permissions
  end

  private

    def role_permissions
      case self.user_role
        when 'admin'
          { admin: { manage: {} }, all: { manage: {} } }
        when 'operator'
          { user: { manage: { id: user.id }} , operator_document: { manage: { operator_id: eval('self.') }},
            observation: { read: {}}}
        # TODO Put this back when the observations-tool support it
        # when 'ngo'
        #   { user: { manage: { id: user.id } },
        #     observation: { manage: { observers: { id: user.observer_id }},  create: {}},
        #     observation_report: { update: { observers: { id: user.observer_id }}, create: {}},
        #     observation_documents:  { ud: { observation: { is_active: false, observers: { id: user.observer_id }}}, create: {}},
        #     category: { read: {}},
        #     subcategory: { read: {}},
        #     government: { read: {}},
        #     species: { read: {}},
        #     operator: { create: {}, read: {}},
        #     law: { read: {}},
        #     severity: { read: {}},
        #     observer: { read: {} ,  update: { id: user.observer_id }},
        #     fmu: { read: {}},
        #     operator_document: { read: {} },
        #     required_operator_document_group: { read: {}},
        #     required_operator_document: { read: {}}
        #   }
        when 'ngo_manager', 'ngo'
          {
              user: { manage: { id: user.id } },
              observation: { manage: { observers: { id: user.observer_id }},  create: {}},
              observation_report: { update: { observers: { id: user.observer_id }}, create: {}},
              observation_documents:  { ud: { observation: { is_active: false, observers: { id: user.observer_id }}}, create: {}},
              category: { cru: {}},
              subcategory: { cru: {}},
              government: { cru: {}},
              species: { cru: {}},
              operator: { cru: {}},
              law: { cru: {}},
              severity: { cru: {}},
              observer: { read: {} ,  update: { id: user.observer_id }},
              fmu: { read: {}, update: {}},
              operator_document: { manage: {} },
              required_operator_document_group: { cru: {}},
              required_operator_document: { cru: {}}
          }
        when 'bo_manager'
          {
              user: { manage: { id: user.id }},
              observation: { manage: {}},
              observer: { read: {}},
              operator: { read: {}},
              observation_report: { read: {} },
              observation_documents:  { read: {}},
              category: { read: {}},
              subcategory: { read: {}},
              government: { read: {}},
              species: { read: {}},
              law: { read: {}},
              severity: { read: {}},
              fmu: { read: {}},
              operator_document: { read: {} },
              required_operator_document_group: { read: {}},
              required_operator_document: { read: {}}
          }
        else
          { user: { id: user.id }, observations: { read: {}}}
      end
    end
end

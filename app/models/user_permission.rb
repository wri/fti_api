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
  enum user_role: { user: 0, operator: 1, ngo: 2, admin: 3 }.freeze

  belongs_to :user

  before_update :change_permissions,         if: 'user_role_changed?'
  after_update  :accept_permissions_request, if: 'user.permissions_request.present?'

  def change_permissions
    self.permissions = role_permissions
  end

  private

    def role_permissions
      # case self.user_role
      # when 'admin'    then { admin: { all: [:manage]  }, all: { all: [:manage] } }
      # when 'operator' then { user:  { id: [:manage] }, observation: { all: [:read]   },
      #                        operator_document: { operator_id: [:manage] }}
      # when 'ngo'      then { user:  { id: [:manage] }, observation: { ['observers': {'id': eval('self.user.observer_id')}] => [:manage] },
      #                        photo: { all: [:manage] }, document: { all: [:manage] },
      #                        category: { all: [:manage] }, subcategory: { all: [:manage] },
      #                        country: { all: [:manage] }, government: { all: [:manage]},
      #                        operator: { all: [:manage]}, species: { all: [:manage] },
      #                        observation_document: { ['observers': {'id': eval('self.user.observer_id')}] => [:manage] },
      #                        observation_report: { ['observers': {'id': eval('self.user.observer_id')}] => [:manage]} }
      # else
      #   { user: { id: [:manage] }, observation: { all: [:read] }  }
      # end

      case self.user_role
        when 'admin'
          { admin: { manage: {} }, all: { manage: {} } }
        when 'operator'
          { user: { manage: { id: user.id }} , operator_document: { manage: { operator_id: eval('self.') }},
            observation: { read: {}}}
        when 'ngo'
          { user: { manage: { id: user.id } }, observation: { manage: { observers: { id: user.observer_id }},  create: {}},
            observation_report: { ru: { observers: { id: user.observer_id }}, create: {}},
            observation_documents: { rud: { observers: { id: user.observer_id }}, create: {}},
            category: { cru: {}}, subcategory: { cru: {}}, government: { cru: {}}, species: { cru: {}}, operator: { cru: {}},
            law: { cru: {}}, severity: { cru: {}}, observer: { read: {} ,  update: { id: user.observer_id }},
            fmu: { read: {}, update: {}}, operator_document: { manage: {} }, required_operator_document_group: { cru: {}},
            required_operator_document: { cru: {}}
          }
        else
          { user: { id: user.id }, observations: { read: {}}}
      end
    end

    def accept_permissions_request
      if user_role == user.permissions_request
        self.user.update(permissions_accepted: Time.now, permissions_request: nil)
      end
    end
end

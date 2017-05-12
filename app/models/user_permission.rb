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
      case self.user_role
      when 'admin'    then { admin: { all: [:read]  }, all:         { all: [:manage] } }
      when 'operator' then { user:  { id: [:manage] }, observation: { all: [:read]   } }
      when 'ngo'      then { user:  { id: [:manage] }, observation: { id: [:manage] },
                             photo: { all: [:manage] }, document: { all: [:manage] },
                             category: { all: [:manage] }, annex_governance: { all: [:manage] },
                             annex_operator: { all: [:manage] }, comment: { all: [:manage] },
                             country: { all: [:manage] }, government: { all: [:manage]},
                             law: { all: [:manage] }, observer: { all: [:manage] },
                             operator: { all: [:manage]}, species: { all: [:manage] }}
      else
        { user: { id: [:manage] }, observation: { all: [:read] }  }
      end
    end

    def accept_permissions_request
      if user_role == user.permissions_request
        self.user.update(permissions_accepted: Time.now, permissions_request: nil)
      end
    end
end

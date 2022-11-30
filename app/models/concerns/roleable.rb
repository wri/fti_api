# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  included do
    has_one :user_permission, dependent: :destroy

    after_create :set_permissions, unless: :user_permission

    scope :filter_admins,    -> { joins(:user_permission).where(user_permissions: { user_role: 'admin' })    }
    scope :filter_ngos,      -> { joins(:user_permission).where(user_permissions: { user_role: 'ngo' })      }
    scope :filter_operators, -> { joins(:user_permission).where(user_permissions: { user_role: 'operator' }) }
    scope :filter_users,     -> { joins(:user_permission).where(user_permissions: { user_role: 'user' })     }

    def admin?
      user_permission.user_role.in?('admin')
    end

    def ngo?
      user_permission.user_role.in?('ngo')
    end

    def operator?
      user_permission.user_role.in?('operator')
    end

    def user?
      user_permission.user_role.in?('user')
    end

    def is_active_admin?
      admin? && is_active?
    end

    def is_active_ngo?
      ngo? && is_active?
    end

    def is_active_operator?
      operator? && is_active?
    end

    def is_active_user?
      user? && is_active?
    end

    def role_name
      case user_permission.user_role
      when 'admin'    then 'Admin'
      when 'ngo'      then 'NGO'
      when 'operator' then 'Operator'
      else
        'User'
      end
    end

    private

      def set_permissions
        self.create_user_permission(user_role: :user, permissions: { user: { id: [:manage] }, observation: { all: [:read] }  })
      end
  end

  class_methods do
  end
end

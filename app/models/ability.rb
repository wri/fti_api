# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user=nil)

    alias_action :create, :read, :update, :destroy,       to: :crud
    alias_action :read, :update, :destroy,                to: :rud
    alias_action :create, :read, :update,                 to: :cru
    alias_action :read, :update,                          to: :ru
    alias_action :delete, :update,                        to: :ud

    if user
      if user.activated?
        user.user_permission.permissions.each do |entity, actions|
          actions.each do |action, conditions|
            can action.to_sym, (klass = entity.classify.safe_constantize) ? klass : entity.to_sym, conditions
          end
        end

        cannot [:activate, :deactivate, :destroy], User,           id: user.id
        cannot [:edit, :update],                   UserPermission, user_id: user.id
      else
        can [:read], User, id: user.id
      end
    end
    can :read, [Country, Observer, Operator,
                Fmu, Category, OperatorDocument, RequiredOperatorDocument, RequiredOperatorDocumentGroup,
                ObservationReport, ObservationDocument]
    can :read, Observation, is_active: true
    can :create, Operator, is_active: false
  end
end

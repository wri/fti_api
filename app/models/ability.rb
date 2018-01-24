# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user=nil)

    alias_action :create, :read, :update, :destroy,       to: :crud
    alias_action :read, :update, :destroy,                to: :rud
    alias_action :create, :read, :update,                 to: :cru
    alias_action :read, :update,                          to: :ru
    alias_action :destroy, :update,                       to: :ud

    if user
      if user.activated?
        user.user_permission.permissions.each do |entity, actions|
          actions.each do |action, conditions|
            can action.to_sym, (klass = entity.classify.safe_constantize) ? klass : entity.to_sym, conditions
          end
        end

        cannot [:activate, :deactivate, :destroy], User,           id: user.id
        cannot [:edit, :update],                   UserPermission, user_id: user.id

        if user.user_permission.user_role == 'bo_manager'
          can :read, ActiveAdmin::Page, name: 'Dashboard'
          can :read, ActiveAdmin::Comment
          can :create, ActiveAdmin::Comment
          can :manage, ActiveAdmin::Comment, author_id: user.id

        end

      else
        can [:read], User, id: user.id
      end
    end



    can :read, [Country, Fmu, Category, Subcategory, Law, Species,
                OperatorDocument, RequiredOperatorDocument, RequiredOperatorDocumentGroup,
                ObservationReport, ObservationDocument, Partner, OperatorDocumentAnnex]
    can :read, Observation, is_active: true
    can :read, Observer, is_active: true
    can :read, Operator, is_active: true
    can :create, Operator, is_active: false
  end
end

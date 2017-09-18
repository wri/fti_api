# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user=nil)

    alias_action :create, :read, :update, :destroy, to: :crud
    alias_action :read, :update, :destroy, to: :rud
    alias_action :create, :read, :update, to: :cru
    alias_action :read, :update, to: :ru

    if user
      if user.activated?
        #user.user_permission.permissions.each do |subject, actions_list|
          # actions_list.each do |actions_obj|
          #   actions_obj.each do |f_key, actions|
          #     if f_key.to_s.include?('all')
          #       can actions.map(&:to_sym), (klass = subject.classify.safe_constantize) ? klass : subject.to_sym
          #     elsif f_key.starts_with?('[')
          #       f_key = eval(f_key)
          #       can actions.map(&:to_sym), (klass = subject.classify.safe_constantize) ? klass : subject.to_sym, f_key.first
          #     else
          #       can actions.map(&:to_sym), (klass = subject.classify.safe_constantize) ? klass : subject.to_sym, "#{f_key}": eval("user.#{f_key}")
          #     end
          #   end
          # end
        #end

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
                Fmu, Category, OperatorDocument, RequiredOperatorDocument, RequiredOperatorDocumentGroup]
    can :read, Observation, is_active: true
  end
end

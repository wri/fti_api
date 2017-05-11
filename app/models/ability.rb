# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user=nil)
    if user
      if user.activated?
        user.user_permission.permissions.each do |subject, actions_obj|
          actions_obj.each do |f_key, actions|
            if f_key.to_s.include?('all')
              can actions.map(&:to_sym), (klass = subject.classify.safe_constantize) ? klass : subject.to_sym
            else
              can actions.map(&:to_sym), (klass = subject.classify.safe_constantize) ? klass : subject.to_sym, f_key.to_sym => user.id
            end
          end
        end

        cannot [:activate, :deactivate, :destroy], User,           id: user.id
        cannot [:edit, :update],                   UserPermission, user_id: user.id
      else
        can [:read], User, id: user.id
      end
    else
      can :read, :observation
    end
  end
end

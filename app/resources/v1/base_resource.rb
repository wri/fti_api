module V1
  class BaseResource < JSONAPI::Resource
    abstract

    before_save :authorize
    before_remove :authorize

    def observations_tool_user?
      context[:app] == "observations-tool" && context[:current_user].present? &&
        ["ngo", "ngo_manager", "admin"].include?(context[:current_user].user_permission.user_role)
    end

    def admin_user?
      context[:current_user].present? && context[:current_user].user_permission.user_role == "admin"
    end

    def authorize
      action = context[:action].to_sym
      action = :destroy if action == :remove
      current_ability.authorize!(action, @model)
    end

    def current_ability
      @current_ability ||= Ability.new(context[:current_user])
    end
  end
end

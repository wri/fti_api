module V1
  class BaseResource < JSONAPI::Resource
    abstract

    def observations_tool_user?
      context[:app] == "observations-tool" && context[:current_user].present? &&
        ["ngo", "ngo_manager", "admin"].include?(context[:current_user].user_permission.user_role)
    end

    def admin_user?
      context[:current_user].present? && context[:current_user].user_permission.user_role == "admin"
    end
  end
end

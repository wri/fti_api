ActiveAdmin.register_page 'Access Control' do
  menu parent: 'User Management', priority: 2
  content do
    render partial: 'manager',
           locals: { users: User.joins(:user_permission).
               where("user_permissions.user_role = #{UserPermission.user_roles[:bo_manager]}") }
  end


  controller do
    def index
      # @collection = User.joins(:user_permission).
      #     where("user_permissions.user_role = #{UserPermission.user_roles[:bo_manager]}")
      render layout: 'active_admin'
    end

    def edit

    end
  end
end
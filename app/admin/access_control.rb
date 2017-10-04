ActiveAdmin.register_page 'Access Control' do
  menu parent: 'User Management', priority: 2
  # content do
  #   render partial: 'manager',
  #          locals: { users: User.joins(:user_permission).
  #              where("user_permissions.user_role = #{UserPermission.user_roles[:bo_manager]}") }
  # end

  # content do
  #   if params["edit"] == "true"
  #     render partial:'form'
  #   else
  #     render partial:'body'
  #   end
  # end

  page_action :edit do |id|
    puts 'cenas'
  end

  controller do
    def index
      render layout: 'active_admin'
    end

    def edit
      @up = User.find(params['format']).user_permission
      render layout: 'active_admin'
    end

    def new
    end
  end


end
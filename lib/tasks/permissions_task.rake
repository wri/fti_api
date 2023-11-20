namespace :permissions do
  desc "Updates the permissions for all users"
  task update: :environment do
    UserPermission.where.not(user_role: :bo_manager).find_each { |x|
      x.change_permissions
      x.save!
    }
  end
end

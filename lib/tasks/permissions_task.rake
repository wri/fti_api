namespace :permissions do
  desc "Updates the permissions for all users"
  task update: :environment do
    UserPermission.find_each { |x|
      x.change_permissions
      x.save!
    }
  end
end

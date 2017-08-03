ActiveAdmin.register User do
  permit_params :email, :password, :password_confirmation, :country_id,
                :institution, :name, :nickname, :web_url, :is_active,
                :observer_id, :operator_id,
                user_permission_attributes: [:user_role]

  filter :name
  filter :institution
  filter :nickname
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  index do
    column 'Role', :user_permission do |user|
      user.user_permission.user_role
    end
    column :name
    column :nickname
    column :email
    column :observer
    column :operator
    column :institution
    column :current_sign_in_at
    column :sign_in_count

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Admin Details' do
      f.inputs for: [:user_permission, f.object.user_permission || UserPermission.new] do |p|
        p.input :user_role, as: :select, collection: UserPermission.user_roles.keys, include_blank: false
      end
      f.input :observer
      f.input :operator
      f.input :country
      f.input :institution
      f.input :name
      f.input :nickname
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :web_url
      f.input :is_active
    end
    f.actions
  end
end

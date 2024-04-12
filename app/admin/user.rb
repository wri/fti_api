# frozen_string_literal: true

ActiveAdmin.register User do
  extend BackRedirectable

  menu false
  permit_params :email, :password, :password_confirmation, :country_id,
    :name, :is_active,
    :observer_id, :operator_id, :holding_id, :locale,
    managed_observer_ids: [],
    responsible_for_country_ids: [],
    user_permission_attributes: [:user_role]

  filter :operator
  filter :observer
  filter :user_permission_user_role_eq,
    label: proc { I18n.t("shared.role") },
    as: :select,
    collection: -> { UserPermission.user_roles }
  filter :name, as: :select
  filter :email, as: :select
  filter :created_at

  controller do
    def scoped_collection
      User.where.not(email: "webuser@example.com").includes([country: :translations], :user_permission)
    end
  end

  controller do
    def update
      model = :user

      if params[model][:password].blank?
        %w[password password_confirmation].each { |p| params[model].delete(p) }
      end

      super
    end
  end

  csv do
    column :is_active
    column "role" do |user|
      user.user_permission&.user_role
    end
    column :name
    column :email
    column "observer" do |user|
      user.observer&.name
    end
    column "operator" do |user|
      user.operator&.name
    end
    column "holding" do |user|
      user.holding&.name
    end
    column :created_at
  end

  index do
    column("Activation") do |user|
      if user.id != current_user.id
        if user.is_active
          a "Deactivate", href: deactivate_admin_user_path(user), "data-method": :put,
            "data-confirm": "Are you sure you want to DEACTIVATE user #{user.name}"
        else
          a "Activate", href: activate_admin_user_path(user), "data-method": :put,
            "data-confirm": "Are you sure you want to ACTIVATE user #{user.name}"
        end
      end
    end
    column :is_active
    column I18n.t("shared.role"), :user_permission do |user|
      user.user_permission&.user_role
    end
    column :country
    column :name
    column :email
    column :observer
    column :operator
    column :holding
    column :current_sign_in_at
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row I18n.t("shared.role") do |user|
        user.user_permission&.user_role
      end
      row :holding if resource.holding?
      row :operator if resource.operator?
      row :responsible_for_countries if resource.admin?
      row :observer if resource.ngo? || resource.ngo_manager?
      row :managed_observers if resource.ngo? || resource.ngo_manager? || resource.admin?
      row :is_active
      row :locale
      row :country
      row :web_url
      row :current_sign_in_at
      row :updated_at
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.object.build_user_permission if f.object.user_permission.nil?
      f.semantic_fields_for :user_permission do |p|
        p.input :user_role, as: :select, collection: UserPermission.user_roles.keys, include_blank: false
      end
      f.input :observer
      f.input :managed_observers
      f.input :operator
      f.input :holding
      f.input :responsible_for_countries, hint: I18n.t("active_admin.users_page.responsible_for_countries_hint"), collection: Country.active.order(:name)
      f.input :country
      f.input :locale, as: :select, collection: I18n.available_locales
      f.input :name
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :is_active
    end
    f.actions
  end

  member_action :activate, method: :put do
    resource.update(is_active: true) unless resource.id == current_user.id
    redirect_to collection_path, notice: I18n.t("active_admin.shared.user_activated")
  end

  member_action :deactivate, method: :put do
    resource.update(is_active: false) unless (resource.id == current_user.id) || (resource.email == "webuser@example.com")
    redirect_to collection_path, notice: I18n.t("active_admin.shared.user_deactivated")
  end
end

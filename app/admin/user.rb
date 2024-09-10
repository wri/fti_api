# frozen_string_literal: true

ActiveAdmin.register User do
  extend BackRedirectable

  menu false
  permit_params :email, :password, :password_confirmation, :country_id,
    :name, :first_name, :last_name, :is_active, :organization_account,
    :observer_id, :operator_id, :holding_id, :locale,
    qc1_observer_ids: [], qc2_observer_ids: [],
    managed_observer_ids: [],
    responsible_for_country_ids: [],
    user_permission_attributes: [:user_role]

  filter :country, as: :select, collection: -> { Country.joins(:users).by_name_asc }
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
      row :organization_account
      row :first_name if resource.first_name.present?
      row :last_name if resource.last_name.present?
      row :name
      row :email
      row I18n.t("shared.role") do |user|
        user.user_permission&.user_role
      end
      row :holding if resource.holding?
      row :operator if resource.operator?
      row :responsible_for_countries if resource.admin?
      row :observer if resource.ngo? || resource.ngo_manager?
      # row :managed_observers if resource.ngo? || resource.ngo_manager? || resource.admin?
      row :qc1_observers if resource.ngo_manager?
      row :qc2_observers if resource.admin? || resource.ngo_manager?
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
      # TODO: remove if removing managed_observers
      # f.input :managed_observers
      f.input :qc1_observers,
        as: :select,
        hint: "You can see the current QC person in parentheses. Setting a new QC person will replace the current one",
        collection: Observer.left_outer_joins(:responsible_qc1).by_name_asc.map { |o| [o.responsible_qc1.present? ? "#{o.name} (QC: #{o.responsible_qc1.name})" : o.name, o.id] }
      f.input :qc2_observers,
        as: :select,
        hint: "You can see the current QC person in parentheses. Setting a new QC person will replace the current one",
        collection: Observer.left_outer_joins(:responsible_qc2).by_name_asc.map { |o| [o.responsible_qc2.present? ? "#{o.name} (QC: #{o.responsible_qc2.name})" : o.name, o.id] }
      f.input :operator
      f.input :holding
      f.input :responsible_for_countries, hint: I18n.t("active_admin.users_page.responsible_for_countries_hint"), collection: Country.active.order(:name)
      f.input :country
      f.input :locale, as: :select, collection: I18n.available_locales
      f.input :name, input_html: {disabled: true}
      f.input :first_name
      f.input :last_name
      f.input :organization_account
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

# frozen_string_literal: true

ActiveAdmin.register Sawmill do
  extend BackRedirectable

  menu false

  config.order_clause

  actions :all
  permit_params :operator_id, :name, :lat, :lng, :is_active

  member_action :activate, method: :put do
    resource.update(is_active: true)
    redirect_to collection_path, notice: I18n.t("active_admin.shared.operator_activated")
  end

  index do
    column :is_active
    column :name
    column :operator, sortable: :name
    column "Latitude", :lat
    column "Longitude", :lng
    column("Actions") do |sawmill|
      unless sawmill.is_active
        a I18n.t("shared.activate"), href: activate_admin_sawmill_path(sawmill),
          "data-method": :put, "data-confirm": "Are you sure you want to ACTIVATE the sawmill #{sawmill.name}?"
      end
    end

    actions
  end

  scope -> { I18n.t("active_admin.all") }, :all, default: true
  scope -> { I18n.t("active_admin.shared.active") }, :active
  scope -> { I18n.t("active_admin.shared.inactive") }, :inactive

  filter :operator, label: proc { I18n.t("filters.operator") }, as: :select,
    collection: -> { Operator.joins(:sawmills).order(name: :asc) }
  filter :name

  form do |f|
    edit = !f.object.new_record?
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Sawmill Details" do
      f.input :operator, input_html: {disabled: edit}
      f.input :name
      f.input :lat, label: "Latitude"
      f.input :lng, label: "Longitude"
      f.input :is_active
    end
    f.actions
  end

  csv do
    column "operator" do |s|
      s.operator&.name
    end
    column :name
    column :lat
    column :lng
    column :is_active
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row :operator
      row :name
      row :lat
      row :lng
      row :is_active
      row :created_at
      row :updated_at
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:operator)
    end
  end
end

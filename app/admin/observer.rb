# frozen_string_literal: true

ActiveAdmin.register Observer, as: "Monitor" do
  extend BackRedirectable
  extend Versionable

  menu false

  config.order_clause

  actions :all

  controller do
    def scoped_collection
      end_of_association_chain.includes(:responsible_qc1, :responsible_qc2, :countries)
    end
  end

  permit_params :observer_type, :is_active, :name, :organization_type,
    :responsible_qc1_id, :responsible_qc2_id, country_ids: []

  csv do
    column :is_active
    column :public_info
    column :countries do |observer|
      observer.countries.map(&:name).join(";")
    end
    column :observer_type
    column :name
    column :created_at
    column :updated_at
  end

  index title: proc { I18n.t("activerecord.models.observer") } do
    column :is_active
    column :public_info
    column :countries do |observer|
      links = []
      observer.countries.each do |country|
        links << link_to(country.name, admin_country_path(country.id))
      end
      safe_join(links, " ")
    end
    column :observer_type, sortable: true
    column :name
    column :responsible_qc1
    column :responsible_qc2
    column :created_at
    column :updated_at
    actions
  end

  filter :is_active
  filter :countries,
    as: :select,
    label: I18n.t("activerecord.models.country.one"),
    collection: -> { Country.joins(:observers).with_translations(I18n.locale).order("country_translations.name").distinct }
  filter :name_eq,
    as: :select,
    label: -> { Observer.human_attribute_name(:name) },
    collection: -> { Observer.by_name_asc.pluck(:name) }

  dependent_filters do
    {
      is_active: {
        name_eq: Observer.pluck(:is_active, :name)
      },
      country_ids: {
        name_eq: Observer.joins(:countries).pluck(:country_id, :name)
      }
    }
  end

  show do
    attributes_table do
      row :is_active
      row :public_info
      row :observer_type
      row :organization_type
      row :responsible_qc1
      row :responsible_qc2
      row :countries do |observer|
        links = []
        observer.countries.each do |country|
          links << link_to(country.name, admin_country_path(country.id))
        end
        safe_join(links, " ")
      end
      row :address
      row :information_name
      row :information_email
      row :information_phone
      row :data_name
      row :data_email
      row :data_phone
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.shared.monitor_details") do
      f.input :name
      f.input :is_active
      f.input :countries, collection: Country.with_translations(I18n.locale).order("country_translations.name asc")
      f.input :observer_type, as: :select, collection: %w[Mandated SemiMandated External Government]
      f.input :organization_type, as: :select, collection: ["NGO", "Academic", "Research Institute", "Private Company", "Other"]
    end
    unless f.object.new_record?
      f.inputs "Quality Control" do
        f.input :responsible_qc1, as: :select, collection: User.with_roles(:ngo_manager).filter_actives
        f.input :responsible_qc2, as: :select, collection: User.with_roles([:admin, :ngo_manager]).filter_actives
      end
    end
    f.inputs Observer.human_attribute_name(:public_info) do
      f.input :public_info, input_html: {disabled: true}
      f.input :address, input_html: {disabled: true}
      f.input :information_name, input_html: {disabled: true}
      f.input :information_email, input_html: {disabled: true}
      f.input :information_phone, input_html: {disabled: true}
      f.input :data_name, input_html: {disabled: true}
      f.input :data_email, input_html: {disabled: true}
      f.input :data_phone, input_html: {disabled: true}
    end
    f.actions
  end
end

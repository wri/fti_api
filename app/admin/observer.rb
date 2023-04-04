# frozen_string_literal: true

ActiveAdmin.register Observer, as: "Monitor" do
  extend BackRedirectable
  extend Versionable

  menu false

  config.order_clause

  actions :all

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale).includes(:responsible_admin, :countries)
    end
  end

  permit_params :observer_type, :is_active, :logo, :organization_type, :delete_logo,
    :responsible_user_id, :responsible_admin_id, translations_attributes: [:id, :locale, :name, :_destroy], country_ids: []

  csv do
    column :is_active
    column :public_info
    column :countries do |observer|
      names = observer.countries.map { |c| c.name }
      names.join(" ").tr(",", ";")
    end
    column :observer_type
    column :name
    column :created_at
    column :updated_at
  end

  index title: I18n.t("activerecord.models.observer") do
    column :is_active
    column :public_info
    # TODO: Reactivate rubocop and fix this
    # rubocop:disable Rails/OutputSafety
    column :countries do |observer|
      links = []
      observer.countries.each do |country|
        links << link_to(country.name, admin_country_path(country.id))
      end
      links.join(" ").html_safe
    end
    # rubocop:enable Rails/OutputSafety
    column :observer_type, sortable: true
    column :logo do |o|
      link_to o.logo&.identifier, o.logo&.url if o.logo&.url
    end
    column :name, label: I18n.t("activerecord.attributes.observer/translation.name"), sortable: "observer_translations.name"
    column :responsible_user
    column :responsible_admin
    column :created_at
    column :updated_at
    actions
  end

  filter :is_active
  filter :countries,
    as: :select,
    label: I18n.t("activerecord.models.country.one"),
    collection: -> { Country.joins(:observers).with_translations(I18n.locale).order("country_translations.name").distinct }
  filter :translations_name_eq,
    as: :select,
    label: -> { I18n.t("activerecord.attributes.observer/translation.name") },
    collection: -> { Observer.by_name_asc.pluck(:name) }

  dependent_filters do
    {
      is_active: {
        translations_name_eq: Observer.pluck(:is_active, :name)
      },
      country_ids: {
        translations_name_eq: Observer.joins(:countries).pluck(:country_id, :name)
      }
    }
  end

  show do
    attributes_table do
      row :is_active
      row :public_info
      row :observer_type
      row :organization_type
      row :responsible_user
      row :responsible_admin
      # TODO: Reactivate rubocop and fix this
      # rubocop:disable Rails/OutputSafety
      row :countries do |observer|
        links = []
        observer.countries.each do |country|
          links << link_to(country.name, admin_country_path(country.id))
        end
        links.join(" ").html_safe
      end
      # rubocop:enable Rails/OutputSafety
      row :logo do |o|
        link_to o.logo&.identifier, o.logo&.url
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
    f.inputs I18n.t("active_admin.shared.translated_fields") do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end
    f.inputs I18n.t("active_admin.shared.monitor_details") do
      f.input :is_active
      f.input :responsible_user, as: :select, collection: User.where(observer_id: f.object.id)
      f.input :responsible_admin, as: :select, collection: User.joins(:user_permission).where(user_permissions: {user_role: :admin})
      f.input :countries, collection: Country.with_translations(I18n.locale).order("country_translations.name asc")
      f.input :observer_type, as: :select, collection: %w[Mandated SemiMandated External Government]
      f.input :organization_type, as: :select, collection: ["NGO", "Academic", "Research Institute", "Private Company", "Other"]
      if f.object.logo.present?
        f.input :logo, as: :file, hint: image_tag(f.object.logo.url(:thumbnail))
        f.input :delete_logo, as: :boolean, required: false, label: "Remove logo"
      else
        f.input :logo, as: :file
      end
    end
    f.inputs I18n.t("activerecord.attributes.observer.public_info") do
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

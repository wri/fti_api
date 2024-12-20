# frozen_string_literal: true

ActiveAdmin.register Country do
  extend BackRedirectable

  menu false

  actions :show, :index, :edit, :update, :create

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.with_translations
    end
  end

  scope -> { I18n.t("active_admin.all") }, :all
  scope -> { I18n.t("active_admin.shared.active") }, :active

  filter :iso, as: :select
  filter :translations_name_cont, as: :select,
    label: -> { I18n.t("activerecord.attributes.country.name") },
    collection: -> { Country.order(:name).pluck(:name) }
  filter :region_iso, as: :select
  filter :region_name
  filter :is_active

  permit_params responsible_admin_ids: [], translations_attributes: [:id, :locale, :name, :overview, :vpa_overview, :_destroy]

  csv do
    column :is_active
    column :id
    column :iso
    column :name
    column :region_iso
    column :region_name
  end

  index do
    column :is_active, sortable: true
    column :id, sortable: true
    column :iso, sortable: true
    column :name, sortable: "country_translations.name"
    column :region_iso, sortable: true
    column :region_name, sortable: "country_translations.region_name"

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.shared.country_details") do
      f.input :responsible_admins, collection: User.filter_actives.filter_admins.order(:name)
      f.translated_inputs "Translations", switch_locale: false do |t|
        t.input :name
        t.input :overview, as: :html_editor
        t.input :vpa_overview, as: :html_editor
      end

      f.actions
    end
  end

  show do
    attributes_table do
      row :name
      row :iso
      row :region_iso
      row :is_active
      row :responsible_admins
      # rubocop:disable Rails/OutputSafety
      row(:overview) { |c| c.overview&.html_safe }
      row(:vpa_overview) { |c| c.vpa_overview&.html_safe }
      # rubocop:enable Rails/OutputSafety
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end

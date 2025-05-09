# frozen_string_literal: true

ActiveAdmin.register ObservationReport do
  extend BackRedirectable
  extend Versionable

  menu false

  actions :all, except: [:new]

  permit_params :user_id, :title, :publication_date, :attachment, observer_ids: []

  config.order_clause
  active_admin_paranoia

  controller do
    def scoped_collection
      end_of_association_chain.includes([:observers, [observations: :translations], [observations: [country: :translations]]])
    end

    def apply_filtering(chain)
      super.distinct
    end
  end

  member_action :really_destroy, method: :delete do
    if resource.deleted?
      resource.really_destroy!
      redirect_back fallback_location: admin_observation_report_path, notice: I18n.t("active_admin.shared.report_removed")
    else
      redirect_back fallback_location: admin_observation_report_path, notice: I18n.t("active_admin.shared.recycle_report")
    end
  end

  filter :observations_country_id,
    as: :select,
    label: -> { I18n.t("activerecord.models.country.one") },
    collection: -> { Country.with_observations.by_name_asc }
  filter :title, as: :select
  filter :observers, as: :select, label: -> { I18n.t("activerecord.attributes.observation.observers") }, collection: -> { Observer.by_name_asc }
  filter :observations, as: :select, collection: -> { Observation.order(:id).pluck(:id) }
  filter :publication_date

  dependent_filters do
    {
      observations_country_id: {
        title: ObservationReport.joins(observations: :country).distinct.pluck(:country_id, :title),
        observer_ids: Observer.joins(:countries).pluck(:country_id, :id)
      }
    }
  end

  config.clear_action_items!

  action_item :edit_report, only: [:show] do
    link_to I18n.t("active_admin.shared.edit_report"), edit_admin_observation_report_path(observation_report)
  end

  action_item :delete_report, only: [:show], unless: -> { observation_report.deleted? } do
    link_to I18n.t("active_admin.shared.delete_report"), admin_observation_report_path(observation_report),
      method: :delete, data: {confirm: ObservationReportDecorator.new(observation_report).delete_confirmation_text}
  end

  csv do
    column :id
    column :title
    column :publication_date
    column :attachment
    column I18n.t("activerecord.models.user") do |obsr|
      obsr.user&.name
    end
    column I18n.t("activerecord.models.observation.other") do |obsr|
      obsr.observations.map(&:id).sort.join(", ")
    end
    column :country do |o|
      o.observations.first&.country&.name
    end
    column I18n.t("activerecord.attributes.observation_report.observers") do |o|
      o.observers.map(&:name).sort.join(", ")
    end
    column :created_at
    column :updated_at
  end

  index do
    column :id
    column :title do |report|
      if report.deleted?
        report.title
      else
        link_to(report.title, admin_observation_report_path(report.id))
      end
    end
    column :publication_date
    column :attachment do |o|
      link_to o.attachment&.identifier, o.attachment&.url
    end
    column :user
    column :country do |o|
      country = o.observations.first&.country
      link_to(country.name, admin_country_path(country.id)) if country
    end
    column :observations do |o|
      links = []
      o.observations.sort_by(&:id).each do |obs|
        links << link_to(obs.id, admin_observation_path(obs.id))
      end
      links.reduce(:+)
    end
    column :observers do |o|
      links = []
      o.observers.find_each do |observer|
        links << link_to(observer.name, admin_monitor_path(observer.id))
      end
      links.reduce(:+)
    end
    column :created_at
    column :updated_at

    actions defaults: false do |report|
      if report.deleted?
        item I18n.t("active_admin.shared.restore"), restore_admin_observation_report_path(report), method: :put
        item I18n.t("active_admin.shared.remove_completely"), really_destroy_admin_observation_report_path(report),
          method: :delete, data: {confirm: "Are you sure you want to remove the report completely? This action is not reversible."}
      else
        item I18n.t("active_admin.shared.view"), admin_observation_report_path(report)
        item I18n.t("active_admin.shared.edit"), edit_admin_observation_report_path(report)
        item I18n.t("active_admin.shared.delete"), admin_observation_report_path(report),
          method: :delete, data: {confirm: ObservationReportDecorator.new(report).delete_confirmation_text}
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.shared.report_details") do
      f.input :user
      f.input :title
      f.input :publication_date, as: :date_time_picker, picker_options: {timepicker: false, format: "Y-m-d"}
      f.input :attachment, as: :file, hint: f.object&.attachment&.file&.filename
      f.input :observers
    end

    f.actions
  end

  show do
    attributes_table do
      row :title
      row :publication_date
      row :observers
      row :observations
      row :observation_documents
      row :user
      row :created_at
      row :updated_at
      row :deleted_at
      row :attachment do |o|
        link_to o.attachment&.identifier, o.attachment&.url
      end
    end
    active_admin_comments
  end
end

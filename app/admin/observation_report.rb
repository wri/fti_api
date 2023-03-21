# frozen_string_literal: true

ActiveAdmin.register ObservationReport do
  extend BackRedirectable
  extend Versionable

  menu false

  actions :all, except: [:new]

  permit_params :user_id, :title, :publication_date, :attachment

  config.order_clause
  active_admin_paranoia

  controller do
    def scoped_collection
      end_of_association_chain.includes([[observation_report_observers: [observer: :translations]],
                                         [observations: :translations], [observations: [country: :translations]]])
    end

    def apply_filtering(chain)
      super(chain).distinct
    end
  end

  member_action :really_destroy, method: :delete do
    if resource.deleted?
      resource.really_destroy!
      redirect_back fallback_location: admin_observation_report_path, notice: I18n.t('active_admin.shared.report_removed')
    else
      redirect_back fallback_location: admin_observation_report_path, notice: I18n.t('active_admin.shared.recycle_report')
    end
  end

  filter :observations_country_id_eq,
         as: :select,
         label: I18n.t('activerecord.models.country.one'),
         collection: -> { Country.with_observations.by_name_asc }
  filter :title, as: :select
  filter :observers,
         as: :dependent_select,
         label: I18n.t('activerecord.attributes.observation.observers'),
         url: -> { admin_monitors_path },
         order: 'observer_translations.name_asc',
         query: {
          translations_name_cont: 'search_term',
          countries_id_eq: 'q_observations_country_id_eq_value'
        }
  filter :observations, as: :select, collection: -> { Observation.order(:id).pluck(:id) }
  filter :publication_date

  config.clear_action_items!

  action_item :edit_report, only: [:show] do
    link_to I18n.t('active_admin.shared.edit_report'), edit_admin_observation_report_path(observation_report)
  end

  action_item :delete_report, only: [:show], unless: -> { observation_report.deleted? } do
    link_to I18n.t('active_admin.shared.delete_report'), admin_observation_report_path(observation_report),
            method: :delete, data: { confirm: ObservationReportDecorator.new(observation_report).delete_confirmation_text }
  end

  csv do
    column :id
    column :title
    column :publication_date
    column :attachment
    column I18n.t('activerecord.models.user') do |obsr|
      obsr.user&.name
    end
    column I18n.t('activerecord.models.observation.other') do |obsr|
      ids = obsr.observations.map { |o| o.id }
      ids.sort.join(', ')
    end
    column :country do |o|
      o.observations.first&.country&.name
    end
    column I18n.t('activerecord.attributes.observation_report.observers') do |o|
      names = o.observers.joins(:translations).map { |o| o.name }
      names.sort.join(', ')
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
      o.observations.each do |obs|
        links << link_to(obs.id, admin_observation_path(obs.id))
      end
      links.reduce(:+)
    end
    column :observers do |o|
      links = []
      o.observers.joins(:translations).each do |observer|
        links << link_to(observer.name, admin_monitor_path(observer.id))
      end
      links.reduce(:+)
    end
    column :created_at
    column :updated_at

    actions defaults: false do |report|
      if report.deleted?
        item I18n.t('active_admin.shared.restore'), restore_admin_observation_report_path(report), method: :put
        item I18n.t('active_admin.shared.remove_completely'), really_destroy_admin_observation_report_path(report),
             method: :delete, data: { confirm: 'Are you sure you want to remove the report completely? This action is not reversible.' }
      else
        item I18n.t('active_admin.shared.view'), admin_observation_report_path(report)
        item I18n.t('active_admin.shared.edit'), edit_admin_observation_report_path(report)
        item I18n.t('active_admin.shared.delete'), admin_observation_report_path(report),
             method: :delete, data: { confirm: ObservationReportDecorator.new(report).delete_confirmation_text }
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.shared.report_details') do
      f.input :user
      f.input :title
      f.input :publication_date, as: :date_time_picker, picker_options: { timepicker: false, format: 'Y-m-d' }
      f.input :attachment, as: :file, hint: f.object&.attachment&.file&.filename

      f.actions
    end
  end

  show do
    attributes_table do
      row :title
      row :publication_date
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

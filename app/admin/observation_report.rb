# frozen_string_literal: true

ActiveAdmin.register ObservationReport do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  menu false

  actions :all, except: [:new]

  permit_params :user_id, :title, :publication_date, :attachment

  config.order_clause
  active_admin_paranoia

  controller do
    def scoped_collection
      end_of_association_chain.includes([[observation_report_observers: [observer: :translations]],
                                         [observations: :translations]])
    end
  end

  filter :title, as: :select
  filter :attachment, as: :select
  filter :user, as: :select, collection: User.order(:name)
  filter :observers, label: 'Observers', as: :select,
                     collection: -> { Observer.with_translations(I18n.locale).order('observer_translations.name') }
  filter :observations, as: :select, collection: Observation.order(:id).pluck(:id)
  filter :publication_date

  config.clear_action_items!

  action_item only: [:show] do
    link_to 'Edit Report', edit_admin_observation_report_path(observation_report)
  end

  action_item only: [:show], unless: -> { observation_report.deleted? } do
    link_to 'Delete Report', admin_observation_report_path(observation_report),
            method: :delete, data: { confirm: ObservationReportDecorator.new(observation_report).delete_confirmation_text }
  end

  csv do
    column :id
    column :title
    column :publication_date
    column :attachment
    column 'user' do |obsr|
      obsr.user&.name
    end
    column 'observations' do |obsr|
      ids = obsr.observations.map { |o| o.id }
      ids.reduce(:+)
    end
    column 'observers' do |o|
      names = o.observers.joins(:translations).map { |o| o.name }
      names.reduce(:+)
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
    attachment_column :attachment
    column :user
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
        link_to "Restore", restore_admin_observation_report_path(report), method: :put
      else
        item "View", admin_observation_report_path(report)
        text_node "<br/>".html_safe
        item "Edit", edit_admin_observation_report_path(report)
        text_node "<br/>".html_safe
        link_to 'Delete', admin_observation_report_path(report),
                method: :delete, data: { confirm: ObservationReportDecorator.new(report).delete_confirmation_text }
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Report Details' do
      f.input :user
      f.input :title
      f.input :publication_date, as: :date_time_picker, picker_options: { timepicker: false }
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
      attachment_row('File', :attachment, label: 'Download File')
    end
    active_admin_comments
  end
end

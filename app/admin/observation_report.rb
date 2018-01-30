# frozen_string_literal: true

ActiveAdmin.register ObservationReport do
  menu false

  actions :show, :index, :update, :edit

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
  filter :user, as: :select
  filter :observers
  filter :observations, as: :select, collection: Observation.pluck(:id)
  filter :publication_date

  index do
    column :id
    column :title do |report|
      link_to(report.title, admin_observation_report_path(report.id))
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

    actions
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

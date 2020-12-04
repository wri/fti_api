# frozen_string_literal: true

ActiveAdmin.register GlobalObservationScore do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index, :show

  index do
    column :date
    column :obs_total
    column :rep_total
    column :rep_country
    column :rep_monitor
    column :obs_country
    column :obs_status
    column :obs_producer
    column :obs_severity
    column :obs_category
    column :obs_subcategory
    column :obs_fmu
    column :obs_forest_type
    column :created_at
    column :updated_at
    actions

    grouped_sod = GlobalObservationScore.group_by_month(:date, series: false)
    render partial: 'score_evolution', locals: {
        scores: [
            { name: 'Observations', data: grouped_sod.maximum(:obs_total) },
            { name: 'Reports', data: grouped_sod.maximum(:rep_total) }
        ]
    }
  end
end

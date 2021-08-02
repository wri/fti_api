# frozen_string_literal: true

ActiveAdmin.register ObservationReport, as: 'Observation Report Dashboard' do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index

  index do
    column :date
    actions

    grouped_sod = GlobalObservationScore.group_by_month(:date, series: false)
    render partial: 'score_evolution', locals: {
      scores: [
        { name: 'Observations', data: grouped_sod.maximum(:obs_total) },
        { name: 'Reports', data: grouped_sod.maximum(:rep_total) }
      ]
    }
  end

  controller do
    def scoped_collection
      ObservationReport.group('created_at::date')
    end
  end
end

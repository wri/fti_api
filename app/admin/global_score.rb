# frozen_string_literal: true

ActiveAdmin.register GlobalScore do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index, :show

  index do
    GlobalScore.headers.each do |h|
      if h.is_a?(Hash)
        h.values.first.each do |k|
          column "#{h.keys.first} #{k.first}" do |gs|
            gs[h.keys.first][k.last.to_s]
          end
        end
      else
        column h.to_sym, sortable: false
      end
    end
    column :created_at
    column :updated_at
    actions

    grouped_sod = GlobalScore.group_by_day(:date, series: false)
    render partial: 'score_evolution', locals: {
        scores: [
            { name: 'all', data: grouped_sod.maximum(:total_required) },
            { name: 'Not Provided', data: grouped_sod.maximum("general_status->>'doc_not_provided'") },
            { name: 'Pending', data: grouped_sod.maximum("general_status->>'doc_pending'") },
            { name: 'Invalid', data: grouped_sod.maximum("general_status->>'doc_invalid'") },
            { name: 'Valid', data: grouped_sod.maximum("general_status->>'doc_valid'") },
            { name: 'Expired', data: grouped_sod.maximum("general_status->>'doc_expired'") },
            { name: 'Not Required', data: grouped_sod.maximum("general_status->>'doc_not_required'") },
        ]
    }
  end
end

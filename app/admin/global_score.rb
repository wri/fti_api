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
  end
end

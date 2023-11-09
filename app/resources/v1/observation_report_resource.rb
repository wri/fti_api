# frozen_string_literal: true

module V1
  class ObservationReportResource < BaseResource
    caching

    attributes :title, :publication_date, :created_at, :updated_at, :attachment

    has_many :observers
    has_one :user
    has_many :observations

    after_create :add_observers

    filter :observer_id, apply: ->(records, value, _options) {
      records.where(id: ObservationReportObserver.where(observer_id: value[0].to_i).select(:observation_report_id))
    }

    def add_observers
      @model.update_observers if @model.observations.any?
    end
  end
end

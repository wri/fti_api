# frozen_string_literal: true

module V1
  class ObservationReportResource < BaseResource
    caching

    attributes :title, :publication_date, :mission_type, :created_at, :updated_at, :attachment

    has_many :observers
    has_many :observations

    filter :observer_id, apply: ->(records, value, _options) {
      records.where(id: ObservationReportObserver.where(observer_id: value[0].to_i).select(:observation_report_id))
    }

    def fetchable_fields
      return super if observations_tool_user?

      super - [:created_at, :updated_at, :user]
    end
  end
end

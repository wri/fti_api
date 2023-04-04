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
      records.where(id: ObservationReportObserver.where(observer_id: value[0].to_i).pluck(:observation_report_id))
    }

    # TODO: Reactivate rubocop and fix this
    # rubocop:disable Lint/RescueException
    def add_observers
      @model.observer_ids = @model.observations.map(&:observers).map(&:ids).flatten if @model.observations.any?
      @model.save
    rescue Exception => e
      Rails.logger.warn "ObservationReport created without observers: #{e.inspect}"
    end
    # rubocop:enable Lint/RescueException
  end
end

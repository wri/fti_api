# frozen_string_literal: true

module V1
  class ObservationReportResource < JSONAPI::Resource
    caching

    attributes :title, :publication_date, :created_at, :updated_at, :attachment

    has_many :observers
    has_one :user
    has_many :observations

    after_create :add_observers

    def custom_links(_)
      { self: nil }
    end

    filter :observer_id, apply: ->(records, value, _options) {
      records.joins(:observers).where('observers.id = ?', value[0].to_i).distinct
    }

    # TODO: Reactivate rubocop and fix this
    # rubocop:disable Lint/RescueException
    def add_observers
      begin
        @model.observer_ids = @model.observations.map(&:observers).map(&:ids).flatten if @model.observations.any?
        @model.save
      rescue Exception => e
        Rails.logger.warn "ObservationReport created without observers: #{e.inspect}"
      end
    end
    # rubocop:enable Lint/RescueException
  end
end

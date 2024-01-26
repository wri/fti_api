# frozen_string_literal: true

module V1
  class ObservationDocumentResource < BaseResource
    caching

    attributes :name, :attachment, :document_type, :observation_report_id, :created_at, :updated_at

    has_many :observations
    has_one :observation_report

    filters :observation_report_id, :name

    filter :observation_id, apply: ->(records, value, _options) {
      records.where(id: ObservationDocument.joins(:observations).where(observations: value))
    }
  end
end

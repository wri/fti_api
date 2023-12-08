# frozen_string_literal: true

module V1
  class ObservationDocumentResource < BaseResource
    caching

    attributes :name, :attachment, :created_at, :updated_at

    has_one :observation

    filters :observation_id, :name
  end
end

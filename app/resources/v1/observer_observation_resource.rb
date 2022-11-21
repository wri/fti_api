# frozen_string_literal: true

module V1
  class ObserverObservationResource < BaseResource
    caching

    has_one :observation
    has_one :observer
  end
end

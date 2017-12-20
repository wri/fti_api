# frozen_string_literal: true

module V1
  class ObserverObservationResource < JSONAPI::Resource
    caching

    has_one :observation
    has_one :observer

    def custom_links(_)
      { self: nil }
    end
  end
end

# frozen_string_literal: true

module V1
  class CountryVpaResource < JSONAPI::Resource
    include CacheableByLocale
    immutable
    caching

    has_one :country

    attributes :position, :url, :name, :description, :country_id

    filter :country

    def self.default_sort
      [{ field: :position, direction: :asc }]
    end

    def self.records(options = {})
      CountryVpa.where(active: true)
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

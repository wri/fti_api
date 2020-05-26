# frozen_string_literal: true

module V1
  class CountryLinkResource < JSONAPI::Resource
    include CacheableByLocale
    immutable
    caching

    has_one :country

    attributes :position, :url, :name, :description, :country_id

    def self.default_sort
      [{ field: :position, direction: :asc }]
    end

    def self.records(options = {})
      CountryLink.where(active: true)
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

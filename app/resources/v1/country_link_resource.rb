# frozen_string_literal: true

module V1
  class CountryLinkResource < BaseResource
    include CacheableByLocale
    immutable
    caching

    has_one :country

    attributes :position, :url, :name, :description, :country_id

    filter :country

    def self.default_sort
      [{field: :position, direction: :asc}]
    end

    def self.records(options = {})
      CountryLink.where(active: true)
    end
  end
end

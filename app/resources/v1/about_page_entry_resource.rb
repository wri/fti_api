# frozen_string_literal: true

module V1
  class AboutPageEntryResource < JSONAPI::Resource
    include CacheableByLocale
    immutable
    caching

    attributes :position, :title, :body

    def self.default_sort
      [{ field: :position, direction: :asc }]
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

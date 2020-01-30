# frozen_string_literal: true

module V1
  class ToolResource < JSONAPI::Resource
    include CacheableByLocale
    immutable
    caching

    attributes :position, :name, :description

    def self.default_sort
      [{ field: :position, direction: :asc }]
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

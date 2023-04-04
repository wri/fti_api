# frozen_string_literal: true

module V1
  class AboutPageEntryResource < BaseResource
    include CacheableByLocale
    immutable
    caching

    attributes :position, :title, :body, :code

    def self.default_sort
      [{field: :position, direction: :asc}]
    end
  end
end

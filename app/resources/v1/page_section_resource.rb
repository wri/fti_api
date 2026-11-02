# frozen_string_literal: true

module V1
  class PageSectionResource < BaseResource
    include CacheableByLocale

    caching
    immutable

    attributes :position, :code, :title, :body

    has_one :page

    def self.default_sort
      [{field: :position, direction: :asc}]
    end
  end
end

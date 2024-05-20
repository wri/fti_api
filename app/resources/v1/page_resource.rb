# frozen_string_literal: true

module V1
  class PageResource < BaseResource
    include CacheableByLocale

    caching
    immutable

    attributes :title, :slug, :body

    filters :slug
  end
end

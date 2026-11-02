# frozen_string_literal: true

module V1
  class PageResource < BaseResource
    include CacheableByLocale

    caching
    immutable

    attributes :title, :slug, :body

    has_many :sections, class_name: "PageSection"

    filters :slug
  end
end

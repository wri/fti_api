# frozen_string_literal: true

module V1
  class CategoryResource < BaseResource
    include CacheableByLocale
    caching

    attributes :name, :category_type

    has_many :subcategories
    filter :category_type
  end
end

# frozen_string_literal: true

module V1
  class CategoryResource < JSONAPI::Resource
    include CachableByLocale
    caching

    attributes :name, :category_type

    has_many :subcategories
    filter :category_type

    def custom_links(_)
      { self: nil }
    end
  end
end

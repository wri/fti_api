module V1
  class CategoryResource < JSONAPI::Resource
    caching

    attributes :name, :category_type

    has_many :subcategories
    filter :category_type

    def custom_links(_)
      { self: nil }
    end

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      return {
          locale: context[:locale]
      }
    end
  end
end

module V1
  class FaqResource < JSONAPI::Resource
    include CacheableByLocale
    immutable
    caching

    attributes :position, :question, :answer, :image

    def self.default_sort
      [{field: :position, direction: :asc}]
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

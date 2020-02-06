# frozen_string_literal: true

module V1
  class DonorResource < JSONAPI::Resource
    include CacheableByLocale
    caching
    immutable

    attributes :name, :website, :logo, :priority, :category, :description

    def custom_links(_)
      { self: nil }
    end
  end
end

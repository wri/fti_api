# frozen_string_literal: true

module V1
  class DonorResource < BaseResource
    include CacheableByLocale
    caching
    immutable

    attributes :name, :website, :logo, :priority, :category, :description
  end
end

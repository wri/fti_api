# frozen_string_literal: true

module V1
  class FaqResource < BaseResource
    include CacheableByLocale
    immutable
    caching

    attributes :position, :question, :answer, :image

    def self.default_sort
      [{field: :position, direction: :asc}]
    end
  end
end

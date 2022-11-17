# frozen_string_literal: true

module V1
  class TutorialResource < BaseResource
    include CacheableByLocale
    immutable
    caching

    attributes :position, :name, :description

    def self.default_sort
      [{ field: :position, direction: :asc }]
    end
  end
end

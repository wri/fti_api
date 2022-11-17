# frozen_string_literal: true

module V1
  class RequiredGovDocumentGroupResource < BaseResource
    include CacheableByLocale
    caching
    attributes :name, :position

    has_many :required_gov_documents

    filter :name

    def self.default_sort
      [{ field: 'position', direction: :asc }]
    end
  end
end

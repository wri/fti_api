# frozen_string_literal: true

module V1
  class RequiredOperatorDocumentGroupResource < JSONAPI::Resource
    include CacheableByLocale
    caching
    attributes :name, :position

    has_many :required_operator_documents

    filter :name

    def custom_links(_)
      { self: nil }
    end

    def self.default_sort
      [{field: 'position', direction: :asc}]
    end
  end
end

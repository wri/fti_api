# frozen_string_literal: true

module V1
  class RequiredGovDocumentGroupResource < JSONAPI::Resource
    caching
    attributes :name, :position

    has_many :required_gov_documents

    filter :name

    def custom_links(_)
      { self: nil }
    end

    def self.default_sort
      [{field: 'position', direction: :asc}]
    end

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      {
          locale: context[:locale]
      }
    end
  end
end

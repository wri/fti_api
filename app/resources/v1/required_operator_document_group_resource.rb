# frozen_string_literal: true

module V1
  class RequiredOperatorDocumentGroupResource < JSONAPI::Resource
    caching
    attributes :name

    has_many :required_operator_documents

    filter :name

    def custom_links(_)
      { self: nil }
    end

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      {
          locale: context[:locale]
      }
    end
  end
end

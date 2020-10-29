# frozen_string_literal: true

module V1
  class OperatorDocumentHistoryResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    include OperatorDocumentable
    caching
    immutable

    def attachment
      return @model.attachment if can_see_document? || document_public?

      { url: nil }
    end

    # TODO
    def self.records(options = {})
      OperatorDocumentHistory.all
    end
  end
end

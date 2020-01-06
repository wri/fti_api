# frozen_string_literal: true

module V1
  class GovFileResource < JSONAPI::Resource
    include CachableByLocale
    include CachableByCurrentUser
    caching
    attributes :attachment, :gov_document_id

    has_one :gov_document

    def custom_links(_)
      { self: nil }
    end
  end
end
